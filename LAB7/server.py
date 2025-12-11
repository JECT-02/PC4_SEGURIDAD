# server.py - API vulnerable: token = base64(data + "." + sha256(key || data))
from flask import Flask, request, jsonify, abort
import hashlib, base64

app = Flask(__name__)

# KEY (server-side secret) - for lab only
# Length = 21 bytes
SECRET_KEY = b"TEST_SECRET_KEY_12345" 

def make_token(data: bytes) -> str:
    # insecure MAC: sha256(key || data)
    mac = hashlib.sha256(SECRET_KEY + data).hexdigest()
    token = base64.b64encode(data + b"." + mac.encode()).decode()
    return token

def verify_token(token_b64: str):
    try:
        # Standard padding fix
        token_b64 += "=" * ((4 - len(token_b64) % 4) % 4)
        raw = base64.b64decode(token_b64)
        
        parts = raw.rsplit(b".", 1)
        if len(parts) != 2:
            print("[DEBUG] Invalid token format (missing dot)")
            return False, None
            
        data, mac = parts[0], parts[1].decode()
        
        # Calculate expected MAC using the secret key
        expected = hashlib.sha256(SECRET_KEY + data).hexdigest()
        
        if expected != mac:
            print(f"[DEBUG] MAC Mismatch!\nExpected: {expected}\nGot:      {mac}")
            return False, None
        
        # Parse data - use latin-1 to handle binary padding from hash extension
        # Then extract key-value pairs, ignoring non-printable chars for the logic
        try:
            data_str = data.decode('latin-1')
        except:
            data_str = data.decode('utf-8', errors='ignore')
        
        # Split on & and parse pairs
        attrs = {}
        # Parse manually to handle duplicate keys (last wins) which is typical behavior
        for pair in data_str.split("&"):
            if "=" in pair:
                key, val = pair.split("=", 1)
                # Simple cleanup of non-printable chars for keys
                clean_key = "".join([c for c in key if c.isprintable()])
                if clean_key:
                    attrs[clean_key] = val
        
        return True, attrs
    except Exception as e:
        print(f"[DEBUG] Token verification error: {e}")
        return False, None

@app.route("/get_token", methods=["GET"])
def get_token():
    # For demo, return token for user_id=15 role=user
    data = b"user_id=15&role=user"
    token = make_token(data)
    return jsonify({"token": token, "data": data.decode()})

@app.route("/resource", methods=["POST"])
def resource():
    # Protected resource that requires role=admin
    token = request.json.get("token","")
    ok, attrs = verify_token(token)
    
    if not ok:
        return jsonify({"ok": False, "error": "invalid token"}), 401
    
    role = attrs.get("role","")
    print(f"[DEBUG] Parsed Role: {role}")
    
    if role == "admin":
        return jsonify({"ok": True, "secret": "FLAG{ADMIN_ACCESS_GRANTED}"}), 200
        
    return jsonify({"ok": False, "error": "insufficient privileges", "role": role}), 403

if __name__ == "__main__":
    print("[+] Server running on port 5000")
    app.run(host="0.0.0.0", port=5000, debug=False)

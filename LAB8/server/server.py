from flask import Flask, request, jsonify, abort
import hashlib, base64

app = Flask(__name__)

# KEY (server-side secret) - for lab only
SECRET_KEY = b"TEST_SECRET_KEY_12345"

def make_token(data: bytes) -> str:
    # insecure MAC: sha256(key || data)
    mac = hashlib.sha256(SECRET_KEY + data).hexdigest()
    token = base64.b64encode(data + b"." + mac.encode()).decode()
    return token

def verify_token(token_b64: str):
    try:
        raw = base64.b64decode(token_b64)
        parts = raw.rsplit(b".", 1)
        if len(parts) != 2:
            return False, None
        data, mac = parts[0], parts[1].decode()
        
        expected = hashlib.sha256(SECRET_KEY + data).hexdigest()
        if expected != mac:
            return False, None
        
        # parse data
        decoded_data = data.decode('utf-8', errors='ignore') 
        attrs = dict(pair.split("=",1) for pair in decoded_data.split("&") if "=" in pair)
        return True, attrs
    except Exception as e:
        return False, None

@app.route("/get_token", methods=["GET"])
def get_token():
    data = b"user_id=15&role=user"
    token = make_token(data)
    return jsonify({"token": token, "data": data.decode()})

@app.route("/resource", methods=["POST"])
def resource():
    token = request.json.get("token","")
    ok, attrs = verify_token(token)
    if not ok:
        return jsonify({"ok": False, "error": "invalid token"}), 401
    
    role = attrs.get("role","")
    if role == "admin":
        return jsonify({"ok": True, "secret": "FLAG{ADMIN_ACCESS_GRANTED}"}), 200
    
    return jsonify({"ok": False, "error": "insufficient privileges", "role": role}), 403

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)

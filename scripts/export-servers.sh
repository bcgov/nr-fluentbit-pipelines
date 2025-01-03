#!/usr/bin/env bash

BROKER_URL=$BROKER_URL
BROKER_JWT=$BROKER_JWT
SERVER_GROUP=$SERVER_GROUP

SERVER_RESPONSE=$(curl -s -X POST $BROKER_URL/v1/collection/server/export \
    -H 'accept: application/json' \
    -H "Authorization: Bearer $BROKER_JWT" \
    -d '' \
    )

if [ "$SERVER_GROUP" = "canary" ]; then
    echo $SERVER_RESPONSE | jq -r 'sort_by(.name) | .[] | select((.tags | index("fluentbit_canary"))) | .name' > servers.txt
fi

if [ "$SERVER_GROUP" = "wildfire_nonproduction" ]; then
    echo $SERVER_RESPONSE | jq -r 'sort_by(.name) | .[] | select((.tags | index("wildfire")) and (.tags | index("nonproduction"))) | .name' > servers.txt
fi

# all tagged, nonproduction servers
if [ "$SERVER_GROUP" = "nonproduction" ]; then
    echo $SERVER_RESPONSE | jq -r 'sort_by(.name) | .[] | select((.tags | length > 0) and (.tags | index("production") == null)) | .name' > servers.txt
fi

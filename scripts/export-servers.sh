#!/usr/bin/env bash

BROKER_URL=$BROKER_URL
BROKER_JWT=$BROKER_JWT
SRV_GROUP=$SRV_GROUP
ENV_GROUP=$ENV_GROUP

SERVER_RESPONSE=$(curl -s -X POST $BROKER_URL/v1/collection/server/export \
    -H 'accept: application/json' \
    -H "Authorization: Bearer $BROKER_JWT" \
    -d '' \
    )

# canary
if [ "$SRV_GROUP" = "canary" ]; then
    echo $SERVER_RESPONSE | jq -r 'sort_by(.name) | .[] | select((.tags | index("canary"))) | .name' > servers.txt
fi

# nonwildfire and nonproduction
if [ "$SRV_GROUP" = "nonwildfire" ] && [ "$ENV_GROUP" = "nonproduction" ]; then
    echo $SERVER_RESPONSE | jq -r \
    'sort_by(.name) | .[] | select((.tags | index("nonwildfire")) and (.tags | index("nonproduction")) and (.tags | index("skip_fluentbit_deploy")) == null) | .name' > servers.txt
fi

# nonwildfire and production
if [ "$SRV_GROUP" = "nonwildfire" ] && [ "$ENV_GROUP" = "production" ]; then
    echo $SERVER_RESPONSE | jq -r \
    'sort_by(.name) | .[] | select((.tags | index("nonwildfire")) and (.tags | index("production")) and (.tags | index("skip_fluentbit_deploy")) == null) | .name' > servers.txt
fi

# wildfire and nonproduction
if [ "$SRV_GROUP" = "wildfire" ] && [ "$ENV_GROUP" = "nonproduction" ]; then
    echo $SERVER_RESPONSE | jq -r \
    'sort_by(.name) | .[] | select((.tags | index("wildfire")) and (.tags | index("nonproduction")) and (.tags | index("skip_fluentbit_deploy")) == null) | .name' > servers.txt
fi

# wildfire and production
if [ "$SRV_GROUP" = "wildfire" ] && [ "$ENV_GROUP" = "production" ]; then
    echo $SERVER_RESPONSE | jq -r \
    'sort_by(.name) | .[] | select((.tags | index("wildfire")) and (.tags | index("production")) and (.tags | index("skip_fluentbit_deploy")) == null) | .name' > servers.txt
fi

#!/usr/bin/env bash

INTENTION_TOKEN=$(echo $FB_INTENTION_JSON | jq -r '.token')

curl -s -X POST $FB_BROKER_URL/v1/intention/close?outcome=$1 -H 'X-Broker-Token: '"$INTENTION_TOKEN"''

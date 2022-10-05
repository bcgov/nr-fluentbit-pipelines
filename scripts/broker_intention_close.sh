#!/usr/bin/env bash

INTENTION_TOKEN=$(echo $INTENTION_JSON | /sw_ux/bin/jq -r '.token')

curl -s -X POST $BROKER_URL/intention/close -H 'X-Broker-Token: '"$INTENTION_TOKEN"''

#!/usr/bin/env bash

ACTION_TOKEN=$(echo $FB_INTENTION_JSON | jq -r ".actions.$2.token")

curl -s -X POST $FB_BROKER_URL/v1/intention/action/$1 -H 'X-Broker-Token: '"$ACTION_TOKEN"''

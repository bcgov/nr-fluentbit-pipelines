#!/usr/bin/env bash

TOKEN=$(echo $INTENTION_JSON | jq -r '.actions.provision.token')

curl -s -X POST $BROKER_URL/v1/provision/approle/secret-id \
  -H 'Content-Type: application/json' \
  -H 'X-Vault-Role-Id: '"$FB_ROLE_ID"'' -H 'X-Broker-Token: '"$TOKEN"'' | \
  jq -r '.wrap_info.token'

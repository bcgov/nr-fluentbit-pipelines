#!/bin/sh

TOKEN=$(echo $INTENTION_JSON | /sw_ux/bin/jq -r '.actions.provision.token')

curl -s -X POST $BROKER_URL/v1/provision/approle/secret-id \
  -H 'Content-Type: application/json' \
  -H 'X-Vault-Role-Id: '"$FB_ROLE_ID"'' -H 'X-Broker-Token: '"$TOKEN"'' | \
  /sw_ux/bin/jq -r '.wrap_info.token'

#!/usr/bin/env bash

TOKEN=$(echo $FB_INTENTION_JSON | jq -r '.actions.login.token')

WRAPPED_VAULT_TOKEN=$(curl -s -X POST $FB_BROKER_URL/v1/provision/token/self \
  -H 'Content-Type: application/json' \
  -H 'X-Vault-Role-Id: '"$FB_CONFIG_ROLE_ID"'' -H 'X-Broker-Token: '"$TOKEN"'' | \
  jq -r '.wrap_info.token')

curl -s -X POST $VAULT_ADDR/v1/sys/wrapping/unwrap \
  -H 'X-Vault-Token: '"$WRAPPED_VAULT_TOKEN"'' | jq -r '.auth.client_token'

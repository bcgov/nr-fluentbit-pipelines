#!/bin/sh

# Workaround because <() does not work
TEMP_FILE=$(mktemp)
cat scripts/provision-fluentbit.json > $TEMP_FILE

curl -s -X POST $BROKER_URL/provision/secret-id -H 'Content-Type: application/json' \
  -H 'X-Vault-Role-Id: '"$FB_ROLE_ID"'' -u "$BASIC_HTTP_USER:$BASIC_HTTP_PASSWORD" \
  -d @$TEMP_FILE | \
  /sw_ux/bin/jq -r '.wrap_info.token'

rm $TEMP_FILE

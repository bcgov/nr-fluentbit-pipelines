#!/bin/sh

# Workaround because <() does not work
TEMP_FILE=$(mktemp)
cat scripts/provision-fluentbit.json > $TEMP_FILE

TOKEN=$(curl -s -X POST $BROKER_URL/intention/open -H 'Content-Type: application/json' -u "$BASIC_HTTP_USER:$BASIC_HTTP_PASSWORD" -d @$TEMP_FILE | jq -r '.token')

curl -s -X POST $BROKER_URL/provision/approle/secret-id -H 'Content-Type: application/json' \
  -H 'X-Vault-Role-Id: '"$FB_ROLE_ID"'' -H 'X-Broker-Token: '"$TOKEN"'' | \
  /sw_ux/bin/jq -r '.wrap_info.token'

rm $TEMP_FILE

# Close intention
curl -s -X POST $BROKER_URL/intention/close -H 'X-Broker-Token: '"$TOKEN"''

#!/bin/sh

# Workaround because <() does not work
TEMP_FILE=$(mktemp)-isss-jenkins-broker
cat $1 | /sw_ux/bin/jq ".event.url=\"$BUILD_URL\" | .event.action=\"job-$JOB_BASE_NAME\"" > $TEMP_FILE

TOKEN=$(curl -s -X POST $BROKER_URL/intention/open -H 'Content-Type: application/json' -u "$BASIC_HTTP_USER:$BASIC_HTTP_PASSWORD" -d @$TEMP_FILE | jq -r '.token')

WRAPPED_VAULT_TOKEN=$(curl -s -X POST $BROKER_URL/provision/token/self \
  -H 'Content-Type: application/json' \
  -H 'X-Vault-Role-Id: '"$CONFIG_ROLE_ID"'' -H 'X-Broker-Token: '"$TOKEN"'' | \
  /sw_ux/bin/jq -r '.wrap_info.token')

rm $TEMP_FILE

VAULT_ADDR=$VAULT_ADDR /sw_ux/bin/vault unwrap -field=token $WRAPPED_VAULT_TOKEN

# Close intention
curl -s -X POST $BROKER_URL/intention/close -H 'X-Broker-Token: '"$TOKEN"''

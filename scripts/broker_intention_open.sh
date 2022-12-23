#!/usr/bin/env bash

# Workaround because <() does not work
TEMP_FILE=$(mktemp)-isss-jenkins-broker
cat $1 | /sw_ux/bin/jq "\
    .event.url=\"$BUILD_URL\" | \
    .user.id=\"$CAUSE_USER_ID\" | \
    (.actions[] | select(.id == \"install\") .service.version) |= \"$FLUENTBIT_RELEASE\" \
    " > $TEMP_FILE

curl -s -X POST $BROKER_URL/v1/intention/open \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $BROKER_JWT" \
    -d @$TEMP_FILE

rm $TEMP_FILE

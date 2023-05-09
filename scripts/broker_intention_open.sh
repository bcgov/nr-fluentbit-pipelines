#!/usr/bin/env bash

# Workaround because <() does not work
TEMP_FILE=$(mktemp)-isss-jenkins-broker
cat $1 | jq "\
    .event.url=\"$FB_BUILD_URL\" | \
    .user.id=\"$FB_CAUSE_USER_ID\" | \
    (.actions[] | select(.id == \"install\") .service.version) |= \"$FB_FLUENTBIT_RELEASE\" \
    " > $TEMP_FILE

curl -s -X POST $FB_BROKER_URL/v1/intention/open \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $FB_NR_BROKER_JWT" \
    -d @$TEMP_FILE

rm $TEMP_FILE

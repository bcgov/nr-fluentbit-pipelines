#!/usr/bin/env bash

jq -r '.apps | map(.id) | join(",")' /app/config/server/$FB_HOSTNAME.json

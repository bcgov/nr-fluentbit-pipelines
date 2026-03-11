#!/usr/bin/env bash
# Test script: provision a wrapped secret ID via broker and test Vault AppRole login.
#
# Required env vars:
#   NR_BROKER_JWT   - broker JWT token
#   FB_ROLE_ID      - Vault AppRole role ID
#   VAULT_TOKEN     - Vault token with unwrap permissions
#
# Optional env vars:
#   BROKER_URL              - defaults to https://broker.io.nrs.gov.bc.ca
#   VAULT_ADDR              - defaults to https://knox.io.nrs.gov.bc.ca
#   FB_VAULT_APPROLE_METHOD - defaults to vs_apps_approle
#   FB_HOSTNAME             - target host name for the install action (required by broker)
#   USER_ID                 - defaults to current unix user

set -euo pipefail

BROKER_URL="${BROKER_URL:-https://broker.io.nrs.gov.bc.ca}"
VAULT_ADDR="${VAULT_ADDR:-https://knox.io.nrs.gov.bc.ca}"
FB_VAULT_APPROLE_METHOD="${FB_VAULT_APPROLE_METHOD:-vs_apps_approle}"
FB_HOSTNAME="${FB_HOSTNAME:-test-host}"
USER_ID="${USER_ID:-$(id -un)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

: "${NR_BROKER_JWT:?NR_BROKER_JWT is required}"
: "${FB_ROLE_ID:?FB_ROLE_ID is required}"
: "${VAULT_TOKEN:?VAULT_TOKEN is required - get one with: vault login -method=ldap username=YOUR_USER}"

# Split curl response body and HTTP status using a unique delimiter
# Usage: http_call <body_var> <status_var> -- curl args...
http_call() {
  local -n _body=$1 _status=$2
  shift 2
  local response
  response=$(curl -s -w $'\x01%{http_code}' "$@")
  _status="${response##*$'\x01'}"
  _body="${response%$'\x01'*}"
}

# Build intention payload with the current user and host
INTENTION_PAYLOAD=$(jq --arg user "$USER_ID" --arg host "$FB_HOSTNAME" \
  '.user.name = $user | .actions[1].cloud.target.instance.name = $host' \
  "$SCRIPT_DIR/intention-fb-install.json")

echo "==> Opening broker intention..."
http_call BODY STATUS -X POST "$BROKER_URL/v1/intention/open" \
  -H "Authorization: Bearer $NR_BROKER_JWT" \
  -H "Content-Type: application/json" \
  -d "$INTENTION_PAYLOAD"
echo "HTTP $STATUS"
echo "$BODY" | jq . || echo "$BODY"
if [[ "$STATUS" != "2"* ]]; then
  echo "ERROR: Failed to open intention (HTTP $STATUS)"
  exit 1
fi
INTENTION_TOKEN=$(echo "$BODY" | jq -r '.token')
PROVISION_TOKEN=$(echo "$BODY" | jq -r '.actions.provision.token')

cleanup() {
  echo "==> Closing broker intention..."
  curl -s -X POST "$BROKER_URL/v1/intention/close" \
    -H "X-Broker-Token: $INTENTION_TOKEN" || true
}
trap cleanup EXIT

echo "==> Starting provision action..."
http_call BODY STATUS -X POST "$BROKER_URL/v1/intention/action/start" \
  -H "X-Broker-Token: $PROVISION_TOKEN" \
  -H "X-Broker-Action-Id: provision"
echo "HTTP $STATUS"
echo "$BODY" | jq . || echo "$BODY"

echo "==> Provisioning wrapped secret ID..."
http_call BODY STATUS -X POST "$BROKER_URL/v1/provision/approle/secret-id" \
  -H "X-Broker-Token: $PROVISION_TOKEN" \
  -H "X-Broker-Action-Id: provision" \
  -H "Content-Type: application/json" \
  -d "{\"roleId\": \"$FB_ROLE_ID\"}"
echo "HTTP $STATUS"
echo "$BODY" | jq . || echo "$BODY"
if [[ "$STATUS" != "2"* ]]; then
  echo "ERROR: Failed to provision secret ID (HTTP $STATUS)"
  exit 1
fi
WRAPPED_FB_SECRET_ID=$(echo "$BODY" | jq -r '.wrap_info.token')

echo "==> Unwrapping secret ID..."
if ! FB_SECRET_ID=$(VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$WRAPPED_FB_SECRET_ID vault unwrap -field=secret_id); then
  echo "ERROR: Failed to unwrap secret ID"
  exit 1
fi
echo "Secret ID unwrapped successfully"

echo "==> Testing AppRole login on auth/$FB_VAULT_APPROLE_METHOD/login ..."
VAULT_ADDR=$VAULT_ADDR vault write \
  "auth/$FB_VAULT_APPROLE_METHOD/login" \
  role_id="$FB_ROLE_ID" \
  secret_id="$FB_SECRET_ID"

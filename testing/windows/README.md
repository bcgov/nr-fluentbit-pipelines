# Testing deployment scripts locally

Follow these instructions to run the deployment scripts from your workstation for testing.

## Requirements

Vault access to the IDIR service account used for deploying Windows Fluent Bit agents and/or OpenShift access to the nr-broker project. 

## Configure environment

Log on to vault using your IDIR credentials and get wrapped Fluent Bit secret ID.

```
export VAULT_ADDR=https://vault-iit.apps.silver.devops.gov.bc.ca
export VAULT_TOKEN=$(vault login -method=oidc -format json | jq -r '.auth.client_token')
```

At this point you may run the remove, copy, base and service deploy scripts.

Before running the start agent script, you must first log in to OpenShift, populate required environment variables and get a wrapped Fluent Bit secret ID. 

Log in to OpenShift using oc.

```
oc login --token=<<redacted>> --server=https://api.silver.devops.gov.bc.ca:6443
```

Source script to set required nr-broker API variables.

```
source setenv-curl-remote.sh a03c8f prod
```

Get wrapped Fluent Bit secret id.
```
export WRAPPED_FB_SECRET_ID=$(VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault write -f -wrap-ttl=120s -f -field=wrapping_token auth/vs_apps_approle/role/fluent_fluent-bit_prod/secret-id)
```

At this point you may run the start agent script.

## Confirm logs in OpenSearch

Log in to OpenSearch to confirm your data was sent.

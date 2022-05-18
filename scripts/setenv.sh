export VAULT_ADDR=https://vault-iit.apps.silver.devops.gov.bc.ca
export VAULT_TOKEN=$(vault login -method=oidc -format json | jq -r '.auth.client_token')
export WRAPPING_TOKEN=$(vault token create -policy=auth/vs_apps_approle/role/fluent_fluent-bit_prod/secret-id-write \
    -policy=shared/groups/appdelivery/jenkins-isss-cdua-read \
    -policy=shared/groups/appdelivery/jenkins-isss-ci-read \
    -policy=auth/vs_apps_approle/role/fluent_fluent-bit_prod/role-id-read \
    -orphan \
    -explicit-max-ttl=300 \
    -wrap-ttl=300 \
    -field=wrapping_token)

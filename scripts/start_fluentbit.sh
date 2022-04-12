#!/bin/sh
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
# become run_user
if [ "$PCI" = "true" ]; then
    sshpass -p $CD_PASS sudo -su $RUN_USER
else
    sudo -su $RUN_USER
fi

# get token
if [ "$PCI" = "true" ]; then
    ROLE_ID=\$(set +x; VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN /sw_ux/bin/vault read -field=role_id auth/vs_apps_approle/role/fluent_fluent-bit_prod/role-id)
    WRAPPING_TOKEN=\$(set +x; VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN /sw_ux/bin/vault write -wrap-ttl=120s -f -field=wrapping_token auth/vs_apps_approle/role/fluent_fluent-bit_prod/secret-id)
    SECRET_ID=\$(set +x; VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=\$WRAPPING_TOKEN /sw_ux/bin/vault unwrap -field=secret_id)
    APP_TOKEN=\$(set +x; VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN /sw_ux/bin/vault write -force -field=token auth/vs_apps_approle/login role_id=\$ROLE_ID secret_id=\$SECRET_ID)
fi

AGENTS=\$(ls -d $AGENT_ROOT/fluent-bit.*)
for agent in \${AGENTS[@]} ; do
    AGENT=\$(basename \$agent)
    AGENT_HOME=$AGENT_ROOT/\$AGENT
    # revoke previous token
    if [ -r \$AGENT_HOME/bin/.env ]; then
        echo "Attempting to revoke previous token..."
        PREVIOUS_TOKEN=\$(cat \$AGENT_HOME/bin/.env | grep VAULT_TOKEN | awk -F '"' '{print \$2}')
        VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=\$PREVIOUS_TOKEN /sw_ux/bin/vault token revoke -self
    fi
    # deploy new token to .env file
    if [ "$PCI" = "true" ]; then 
        sed 's/VAULT_TOKEN=.*/'VAULT_TOKEN=\""\$APP_TOKEN"\"'/g' \$AGENT_HOME/bin/.env.template > \$AGENT_HOME/bin/.env
    else
        sed 's/VAULT_TOKEN=.*/VAULT_TOKEN="$APP_TOKEN"/g' \$AGENT_HOME/bin/.env.template > \$AGENT_HOME/bin/.env
    fi
    chmod 700 \$AGENT_HOME/bin/.env
    if [ -r $S6_SERVICE_HOME/\$AGENT/run ]; then
        /sw_ux/s6/bin/s6-svc -u $S6_SERVICE_HOME/\$AGENT/
    fi
    sleep 1
done
EOF
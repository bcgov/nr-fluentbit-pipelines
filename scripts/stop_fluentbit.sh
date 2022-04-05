#!/bin/sh
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
# become run_user
if [ "$PCI" = "true" ]; then
    sshpass -p $CD_PASS sudo -su $RUN_USER
else
    sudo -su $RUN_USER
fi

AGENTS=\$(ls -d $AGENT_ROOT/fluent-bit.* 2>/dev/null)
if [ "\${#AGENTS[@]}" -gt 0 ]; then
    for agent in \${AGENTS[@]}; do
        AGENT=\$(basename \$agent)
        AGENT_HOME=$AGENT_ROOT/\$AGENT
        if [ -r $S6_SERVICE_HOME/\$AGENT/run ]; then
            /sw_ux/s6/bin/s6-svc -d $S6_SERVICE_HOME/\$AGENT/
        fi
        if [ -r \$AGENT_HOME/bin/.env ]; then
            echo "Attempting to revoke previous token..."
            PREVIOUS_TOKEN=\$(cat \$AGENT_HOME/bin/.env | grep VAULT_TOKEN | awk -F '"' '{print \$2}')
            VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=\$PREVIOUS_TOKEN /sw_ux/bin/vault token revoke -self
        fi
    done
    sleep 5
fi
EOF
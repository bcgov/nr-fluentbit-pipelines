#!/usr/bin/env bash
set +x
echo $SERVER_HOST_KEY > /tmp/known_hosts
sshpass -p $FB_CD_PASS ssh -F /app/ssh-config -q $FB_CD_USER@$FB_HOST /bin/bash <<EOF
sudo -su $FB_RUN_USER

AGENTS=\$(ls -d $FB_AGENT_ROOT/fluent-bit.* 2>/dev/null)
if [ "\${#AGENTS[@]}" -gt 0 ]; then
    for agent in \${AGENTS[@]}; do
        AGENT=\$(basename \$agent)
        AGENT_HOME=$FB_AGENT_ROOT/\$AGENT
        if [ -r $FB_S6_SERVICE_HOME/\$AGENT/run ]; then
            /sw_ux/s6/bin/s6-svc -d $FB_S6_SERVICE_HOME/\$AGENT/
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
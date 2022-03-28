#!/bin/sh
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
# become wwwsvr
sudo -su wwwsvr

AGENTS=\$(ls -d $AGENT_ROOT/fluent-bit.*)
for agent in \${AGENTS[@]} ; do
    AGENT=\$(basename \$agent)
    AGENT_HOME=$AGENT_ROOT/\$AGENT
    # TODO: revoke previous token
    # deploy new token to .env file
    sed -i 's/VAULT_TOKEN=.*/VAULT_TOKEN="${APP_TOKEN}"/g' \$AGENT_HOME/bin/.env
    if [ -r $S6_SERVICE_HOME/\$AGENT/run ]; then
        /sw_ux/s6/bin/s6-svc -u $S6_SERVICE_HOME/\$AGENT/
    fi
    sleep 1
done
EOF
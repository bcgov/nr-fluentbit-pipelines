#!/bin/sh
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
sudo -su wwwadm
# TODO: revoke previous token
# deploy new token to .env file
sed -i 's/VAULT_TOKEN=.*/VAULT_TOKEN="${APP_TOKEN}"/g' $AGENT_HOME/bin/.env
EOF
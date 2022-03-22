#!/bin/sh
set +x
sshpass -p $CD_PASS scp -q -r files $CD_USER@$HOST:
sshpass -p $CD_PASS scp -q -r $FUNBUCKS_OUTPUT $CD_USER@$HOST:
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
sudo -su wwwadm
cp -R output/* $AGENT_HOME/conf
sed "s,\\\$HTTP_PROXY,$HTTP_PROXY,g" files/fluent-bit.hcl > $AGENT_HOME/conf/fluent-bit.hcl
cp files/fluentbitw $AGENT_HOME/bin
cp files/fluent-bit-logrotate.conf ~/
ln -sfn $AGENT_HOME/bin/fluentbitw $S6_SERVICE_DIR/run
EOF
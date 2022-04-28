#!/bin/sh
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
# become install_user
if [ "$PCI" = "true" ]; then
    /sw_ux/bin/sshpass -p $CD_PASS sudo -su $INSTALL_USER
else
    sudo -su $INSTALL_USER
fi

echo "Temp directory: $TMP_DIR"
# create base and agent root
mkdir -p $BIN_DIR
mkdir -p $AGENT_ROOT
chmod 755 $BIN_DIR
chmod 775 $AGENT_ROOT

# download dependencies
/bin/curl -x $HTTP_PROXY -sSL "https://releases.hashicorp.com/vault/${VAULT_RELEASE}/vault_${VAULT_RELEASE}_linux_amd64.zip" -o "$TMP_DIR/bin/vault_${VAULT_RELEASE}_linux_amd64.zip"
/bin/curl -x $HTTP_PROXY -sSL "https://releases.hashicorp.com/envconsul/${ENVCONSUL_RELEASE}/envconsul_${ENVCONSUL_RELEASE}_linux_amd64.zip" -o "$TMP_DIR/bin/envconsul_${ENVCONSUL_RELEASE}_linux_amd64.zip"
/bin/curl -x $HTTP_PROXY -sSL "https://github.com/stedolan/jq/releases/download/jq-${JQ_RELEASE}/jq-linux64" -o $BIN_DIR/jq
/bin/curl -u $CI_USER:$CI_PASS -sSL "http://bwa.nrs.gov.bc.ca/int/artifactory/ext-binaries-local/fluent/fluent-bit/${FLUENTBIT_RELEASE}/fluent-bit.tar.gz" -o $TMP_DIR/bin/fluent-bit.tar.gz
# set jq as executable
chmod 755 $BIN_DIR/jq
# extract bin and lib
cd $TMP_DIR/bin
tar -zxvf $TMP_DIR/bin/fluent-bit.tar.gz --strip-components=1
# unzip vault and envconsul
unzip -o $TMP_DIR/bin/vault_${VAULT_RELEASE}_linux_amd64.zip -d $BIN_DIR
unzip -o $TMP_DIR/bin/envconsul_${ENVCONSUL_RELEASE}_linux_amd64.zip -d $BIN_DIR

# deploy config and exec
cd $TMP_DIR
mkdir -p /apps_data/agents/fluent-bit
chmod 775 /apps_data/agents
chmod 775 /apps_data/agents/fluent-bit
AGENTS=\$(ls -d output/fluent-bit.*)
for agent in \${AGENTS[@]} ; do
    AGENT=\$(basename \$agent)
    AGENT_HOME=$AGENT_ROOT/\$AGENT
    # create agent and service directories
    mkdir -p \$AGENT_HOME/{bin,conf,lib}
    chmod 775 \$AGENT_HOME
    chmod 775 \$AGENT_HOME/{bin,conf,lib}
    mkdir -p $S6_SERVICE_HOME/\$AGENT
    chmod 775 $S6_SERVICE_HOME/\$AGENT
    # Copy files
    cp $TMP_DIR/bin/fluent-bit \$AGENT_HOME/bin
    cp $TMP_DIR/bin/libpq.so.5 \$AGENT_HOME/lib
    cp -R $TMP_DIR/output/\$AGENT/* \$AGENT_HOME/conf
    sed -e "s,\\\$HTTP_PROXY,$HTTP_PROXY,g" -e "s,{{ apm_agent_home }},\$AGENT_HOME,g" $TMP_DIR/files/fluent-bit.hcl > \$AGENT_HOME/conf/fluent-bit.hcl
    cp $TMP_DIR/files/fluentbitw \$AGENT_HOME/bin
    cp $TMP_DIR/files/.env \$AGENT_HOME/bin/.env.template
    ln -sfn \$AGENT_HOME/bin/fluentbitw $S6_SERVICE_HOME/\$AGENT/run
    chmod 664 \$AGENT_HOME/bin/.env.template
    chmod 755 \$AGENT_HOME/bin/fluent-bit \$AGENT_HOME/bin/fluentbitw
    chmod -R a+r,a+X \$AGENT_HOME/conf
done
exit

# become run_user
if [ "$PCI" = "true" ]; then
    /sw_ux/bin/sshpass -p $CD_PASS sudo -su $RUN_USER
else
    sudo -su $RUN_USER
fi
# Trigger adding
/sw_ux/s6/bin/s6-svscanctl -an $S6_SERVICE_HOME
# deploy log rotation
cd $TMP_DIR
mkdir -p /apps_ux/logs/agents/fluent-bit
chmod 775 /apps_ux/logs/agents
chmod 775 /apps_ux/logs/agents/fluent-bit
AGENTS=\$(ls -d output/fluent-bit.*)
for agent in \${AGENTS[@]} ; do
    AGENT=\$(basename \$agent)
    sed "s,{{ apm_agent_log }},/apps_ux/logs/agents/fluent-bit/\$AGENT.log,g" $TMP_DIR/files/fluent-bit-logrotate.conf > /apps_ux/wwwsvr/\$AGENT-logrotate.conf
    croncmd="/sbin/logrotate /apps_ux/wwwsvr/\$AGENT-logrotate.conf --state /apps_ux/wwwsvr/\$AGENT-logrotate-state --verbose"
    cronjob="59 23 * * * \$croncmd"
    ( crontab -l | grep -v -F "\$croncmd" ; echo "\$cronjob" ) | crontab -
done
exit

# clean up
# become install_user
if [ "$PCI" = "true" ]; then
    /sw_ux/bin/sshpass -p $CD_PASS sudo -su $INSTALL_USER
else
    sudo -su $INSTALL_USER
fi
rm -rf $TMP_DIR
exit
EOF
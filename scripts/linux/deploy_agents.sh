#!/usr/bin/env bash
set +x
sshpass -p $FB_CD_PASS ssh -F /app/ssh-config -q $FB_CD_USER@$FB_HOST /bin/bash <<EOF
# become FB_INSTALL_USER
sudo -su $FB_INSTALL_USER

echo "Temp directory: $FB_TMP_DIR"
# create base and agent root
mkdir -p $FB_BIN_DIR
mkdir -p $FB_AGENT_ROOT
chmod 755 $FB_BIN_DIR
chmod 775 $FB_AGENT_ROOT

# download dependencies
if [ -z "$HTTP_PROXY" ]; then
    curl -sSL "https://releases.hashicorp.com/vault/${FB_VAULT_RELEASE}/vault_${FB_VAULT_RELEASE}_linux_amd64.zip" -o "$FB_TMP_DIR/bin/vault_${FB_VAULT_RELEASE}_linux_amd64.zip"
    curl -sSL "https://releases.hashicorp.com/envconsul/${FB_ENVCONSUL_RELEASE}/envconsul_${FB_ENVCONSUL_RELEASE}_linux_amd64.zip" -o "$FB_TMP_DIR/bin/envconsul_${FB_ENVCONSUL_RELEASE}_linux_amd64.zip"
    curl -sSL "https://github.com/stedolan/jq/releases/download/jq-${FB_JQ_RELEASE}/jq-linux64" -o $FB_BIN_DIR/jq
    curl -u $FB_ARTIFACTORY_USERNAME:$FB_ARTIFACTORY_PASSWORD -sSL "https://artifacts.developer.gov.bc.ca/artifactory/cc20-fluent-generic-local/fluent-bit/${FB_FLUENTBIT_RELEASE}/fluent-bit-${FB_OS_VARIANT}.tar.gz" -o $FB_TMP_DIR/bin/fluent-bit.tar.gz
    curl -u $FB_ARTIFACTORY_USERNAME:$FB_ARTIFACTORY_PASSWORD -sSL "https://artifacts.developer.gov.bc.ca/artifactory/cc20-fluent-generic-local/sqlite/sqlite-tools-linux-x64-${FB_SQLITE_RELEASE}.zip" -o $FB_TMP_DIR/bin/sqlite-tools-linux-x64.zip

else
    curl -x $HTTP_PROXY -sSL "https://releases.hashicorp.com/vault/${FB_VAULT_RELEASE}/vault_${FB_VAULT_RELEASE}_linux_amd64.zip" -o "$FB_TMP_DIR/bin/vault_${FB_VAULT_RELEASE}_linux_amd64.zip"
    curl -x $HTTP_PROXY -sSL "https://releases.hashicorp.com/envconsul/${FB_ENVCONSUL_RELEASE}/envconsul_${FB_ENVCONSUL_RELEASE}_linux_amd64.zip" -o "$FB_TMP_DIR/bin/envconsul_${FB_ENVCONSUL_RELEASE}_linux_amd64.zip"
    curl -x $HTTP_PROXY -sSL "https://github.com/stedolan/jq/releases/download/jq-${FB_JQ_RELEASE}/jq-linux64" -o $FB_BIN_DIR/jq
    curl -x $HTTP_PROXY -u $FB_ARTIFACTORY_USERNAME:$FB_ARTIFACTORY_PASSWORD -sSL "https://artifacts.developer.gov.bc.ca/artifactory/cc20-fluent-generic-local/fluent-bit/${FB_FLUENTBIT_RELEASE}/fluent-bit-${FB_OS_VARIANT}.tar.gz" -o $FB_TMP_DIR/bin/fluent-bit.tar.gz
    curl -x $HTTP_PROXY -u $FB_ARTIFACTORY_USERNAME:$FB_ARTIFACTORY_PASSWORD -sSL "https://artifacts.developer.gov.bc.ca/artifactory/cc20-fluent-generic-local/sqlite/sqlite-tools-linux-x64-${FB_SQLITE_RELEASE}.zip" -o $FB_TMP_DIR/bin/sqlite-tools-linux-x64.zip
fi
# set jq as executable
chmod 755 $FB_BIN_DIR/jq
# extract bin and lib
cd $FB_TMP_DIR/bin
tar -zxvf $FB_TMP_DIR/bin/fluent-bit.tar.gz --strip-components=1
# unzip vault and envconsul
unzip -o $FB_TMP_DIR/bin/vault_${FB_VAULT_RELEASE}_linux_amd64.zip -d $FB_BIN_DIR
unzip -o $FB_TMP_DIR/bin/envconsul_${FB_ENVCONSUL_RELEASE}_linux_amd64.zip -d $FB_BIN_DIR
unzip -o $FB_TMP_DIR/bin/sqlite-tools-linux-x64.zip sqlite3 -d $FB_BIN_DIR
# set sqlite3 as executable
chmod 755 $FB_BIN_DIR/sqlite3

# deploy config and exec
cd $FB_TMP_DIR
mkdir -p /apps_data/agents/fluent-bit
chmod 775 /apps_data/agents
chmod 775 /apps_data/agents/fluent-bit
AGENTS=\$(ls -d output/fluent-bit.*)
for agent in \${AGENTS[@]} ; do
    AGENT=\$(basename \$agent)
    AGENT_HOME=$FB_AGENT_ROOT/\$AGENT
    # create agent and service directories
    mkdir -p \$AGENT_HOME/{bin,conf,lib}
    chmod 775 \$AGENT_HOME
    chmod 775 \$AGENT_HOME/{bin,conf,lib}
    mkdir -p $FB_S6_SERVICE_HOME/\$AGENT
    chmod 775 $FB_S6_SERVICE_HOME/\$AGENT
    # Copy files
    cp $FB_TMP_DIR/bin/fluent-bit \$AGENT_HOME/bin
    cp $FB_TMP_DIR/bin/lib* \$AGENT_HOME/lib
    chmod 775 \$AGENT_HOME/lib/*
    cp -R $FB_TMP_DIR/output/\$AGENT/* \$AGENT_HOME/conf
    sed -e "s,\\\$HTTP_PROXY,$HTTP_PROXY,g" -e "s,{{ apm_agent_home }},\$AGENT_HOME,g" $FB_TMP_DIR/files/fluent-bit.hcl > \$AGENT_HOME/conf/fluent-bit.hcl
    cp $FB_TMP_DIR/files/fluentbitw \$AGENT_HOME/bin
    cp $FB_TMP_DIR/files/.env \$AGENT_HOME/bin/.env.template
    cp $FB_TMP_DIR/files/down-signal $FB_S6_SERVICE_HOME\/\$AGENT
    chmod 664 $FB_S6_SERVICE_HOME\/\$AGENT/down-signal
    sed -e "s,\\\$S6_SERVICE_DIR,$FB_S6_SERVICE_HOME\/\$AGENT,g;s/AGENT_NAME=.*/AGENT_NAME=\""\$AGENT"\"/g" $FB_TMP_DIR/files/.env > \$AGENT_HOME/bin/.env.template

    ln -sfn \$AGENT_HOME/bin/fluentbitw $FB_S6_SERVICE_HOME/\$AGENT/run
    chmod 664 \$AGENT_HOME/bin/.env.template
    chmod 755 \$AGENT_HOME/bin/fluent-bit \$AGENT_HOME/bin/fluentbitw
    chmod -R a+r,a+X \$AGENT_HOME/conf
done
exit

# become FB_RUN_USER
sudo -su $FB_RUN_USER
# Trigger adding
/sw_ux/s6/bin/s6-svscanctl -a $FB_S6_SERVICE_HOME
# deploy log rotation
cd $FB_TMP_DIR
mkdir -p /apps_ux/logs/agents/fluent-bit
chmod 775 /apps_ux/logs/agents
chmod 775 /apps_ux/logs/agents/fluent-bit
AGENTS=\$(ls -d output/fluent-bit.*)
for agent in \${AGENTS[@]} ; do
    AGENT=\$(basename \$agent)
    sed "s,{{ apm_agent_log }},/apps_ux/logs/agents/fluent-bit/\$AGENT.log,g" $FB_TMP_DIR/files/fluent-bit-logrotate.conf > /apps_ux/wwwsvr/\$AGENT-logrotate.conf
    croncmd="/sbin/logrotate /apps_ux/wwwsvr/\$AGENT-logrotate.conf --state /apps_ux/wwwsvr/\$AGENT-logrotate-state --verbose"
    cronjob="59 23 * * * \$croncmd"
    ( crontab -l | grep -v -F "\$croncmd" ; echo "\$cronjob" ) | crontab -
done
exit

# clean up
# become FB_INSTALL_USER
sudo -su $FB_INSTALL_USER
rm -rf $FB_TMP_DIR
exit
EOF
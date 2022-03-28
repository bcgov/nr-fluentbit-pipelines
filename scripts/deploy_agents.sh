#!/bin/sh
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
# become wwwadm
sudo -su wwwadm

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
unzip -o $TMP_DIR/bin/vault_1.7.1_linux_amd64.zip -d $BIN_DIR
unzip -o $TMP_DIR/bin/envconsul_0.11.0_linux_amd64.zip -d $BIN_DIR

# deploy config and exec
cd $TMP_DIR
echo "Working directory: \$(pwd)"
AGENTS=\$(ls -d output/fluent-bit.*)
for agent in \${AGENTS[@]} ; do
    AGENT=\$(basename \$agent)
    AGENT_HOME=$AGENT_ROOT/\$AGENT
    if [ -r \$AGENT_HOME ]; then
        mv \$AGENT_HOME $TMP_DIR/backup/\$AGENT
    fi
    # create agent and service directories
    mkdir -p \$AGENT_HOME/{bin,conf,db,lib,logs,scripts}
    mkdir -p $S6_SERVICE_HOME/\$AGENT
    chmod 775 $S6_SERVICE_HOME/\$AGENT
    # Copy files
    cp $TMP_DIR/bin/fluent-bit \$AGENT_HOME/bin
    cp $TMP_DIR/bin/libpq.so.5 \$AGENT_HOME/lib
    cp -R $TMP_DIR/output/\$AGENT/* \$AGENT_HOME/conf
    sed -e "s,\\\$HTTP_PROXY,\$HTTP_PROXY,g" -e "s,{{ apm_agent_home }},\$AGENT_HOME,g" $TMP_DIR/files/fluent-bit.hcl > \$AGENT_HOME/conf/fluent-bit.hcl
    cp $TMP_DIR/files/fluentbitw \$AGENT_HOME/bin
    cp $TMP_DIR/files/.env \$AGENT_HOME/bin/.env.template
    sed "s,{{ apm_agent_home }},\$AGENT_HOME,g" $TMP_DIR/files/fluent-bit-logrotate.conf > \$AGENT_HOME/\$AGENT-logrotate.conf
    ln -sfn \$AGENT_HOME/bin/fluentbitw $S6_SERVICE_HOME/\$AGENT/run
    chmod 775 \$AGENT_HOME/bin/fluentbitw \$AGENT_HOME/db \$AGENT_HOME/logs \$AGENT_HOME/bin
done
EOF
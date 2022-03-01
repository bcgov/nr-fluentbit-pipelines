#!/bin/sh
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
# become wwwadm
sudo -su wwwadm
# create directories
mkdir -p $BIN_DIR
mkdir -p $AGENT_ROOT
mkdir -p $AGENT_HOME/{bin,conf,db,lib,logs,scripts}
mkdir -p $S6_SERVICE_DIR
# set permissions
chmod -R 775 $AGENT_ROOT
chmod 775 $S6_SERVICE_DIR
chmod 755 $BIN_DIR
# download dependencies
/bin/curl -x $HTTP_PROXY -sSL "https://releases.hashicorp.com/vault/${VAULT_RELEASE}/vault_${VAULT_RELEASE}_linux_amd64.zip" -o "/tmp/vault_${VAULT_RELEASE}_linux_amd64.zip"
/bin/curl -x $HTTP_PROXY -sSL "https://releases.hashicorp.com/envconsul/${ENVCONSUL_RELEASE}/envconsul_${ENVCONSUL_RELEASE}_linux_amd64.zip" -o "/tmp/envconsul_${ENVCONSUL_RELEASE}_linux_amd64.zip"
/bin/curl -x $HTTP_PROXY -sSL "https://github.com/stedolan/jq/releases/download/jq-${JQ_RELEASE}/jq-linux64" -o $BIN_DIR/jq
/bin/curl -u $CI_USER:$CI_PASS -sSL "http://bwa.nrs.gov.bc.ca/int/artifactory/ext-binaries-local/fluent/fluent-bit/${FLUENTBIT_RELEASE}/fluent-bit.tar.gz" -o /tmp/fluent-bit.tar.gz
# set jq as executable
chmod 755 $BIN_DIR/jq
# extract bin and lib
cd
tar -zxvf /tmp/fluent-bit.tar.gz --strip-components=1
# move dependencies to agent directories
mv fluent-bit $AGENT_HOME/bin
mv libpq.so.5 $AGENT_HOME/lib
# unzip vault and envconsul
unzip -o /tmp/vault_1.7.1_linux_amd64.zip -d $BIN_DIR
unzip -o /tmp/envconsul_0.11.0_linux_amd64.zip -d $BIN_DIR
EOF
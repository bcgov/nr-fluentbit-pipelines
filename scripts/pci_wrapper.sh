#!/bin/sh

# PCI Wrapper:
# Provides a no-Jenkins Fluent Bit deployment to servers where the standard service account has been disabled

# Set up environment
export CD_USER="${CD_USER}"
export CD_PASS="${CD_PASS}"
export CI_USER="${CI_USER}"
export CI_PASS="${CI_PASS}"
export HOST="${HOST}"
export HOST_SHORT="$(echo ${HOST} | sed 's/\..*$//')"
export PCI="true"
export INSTALL_USER="wwwadm"
export RUN_USER="wwwsvr"
export AGENT_ROOT="/apps_ux/agents"
export S6_SERVICE_HOME="/apps_ux/s6_services"
export RANDOM_STR=$(cat /proc/sys/kernel/random/uuid | sed 's/[-]//g' | head -c 8)
export TMP_DIR="/tmp/fluent-bit.${RANDOM_STR}"
export FUNBUCKS_HOME="${FUNBUCKS_HOME}"
export FUNBUCKS_OUTPUT="${FUNBUCKS_HOME}/output"
export BIN_DIR="/sw_ux/bin"
export AGENT_ROOT="/apps_ux/agents"
export VAULT_RELEASE="1.7.1"
export ENVCONSUL_RELEASE="0.11.0"
export JQ_RELEASE="1.6"
export SQLITE_RELEASE="3.38.5"
export FLUENTBIT_RELEASE="$(cat ${FUNBUCKS_HOME}/config/server/${HOST_SHORT}.json | jq '.fluentBitRelease')"
export HTTP_PROXY="$(cat ${FUNBUCKS_HOME}/config/server/${HOST_SHORT}.json | jq '.proxy')"
export HTTPS_PROXY="$(cat ${FUNBUCKS_HOME}/config/server/${HOST_SHORT}.json | jq '.proxy')"
export NO_PROXY="https://vault-iit.apps.silver.devops.gov.bc.ca"
export VAULT_ADDR="https://vault-iit.apps.silver.devops.gov.bc.ca"
export VAULT_TOKEN="${VAULT_TOKEN}"

# stop agents
scripts/stop_fluentbit.sh

# remove_agents
scripts/remove_agents.sh

# copy files
scripts/copy_files.sh

# deploy agents
scripts/deploy_agents.sh

# start agents
scripts/start_fluentbit.sh

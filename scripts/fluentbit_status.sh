#!/usr/bin/env bash
set +x

SERVER_CONFIGS=$(ls -d /app/fb/config/server/*.json 2>/dev/null)
BASE_FB_RELEASE=$(cat /app/fb/config/base.json | jq -r '.fluentBitRelease')
echo "Base release: $BASE_FB_RELEASE"
if [ "${#SERVER_CONFIGS[@]}" -gt 0 ]; then
    for SERVER_CONFIG in ${SERVER_CONFIGS[@]} ; do
        export FB_HOST=$(cat $SERVER_CONFIG | jq -r '.address')
        export FB_RELEASE=$(cat $SERVER_CONFIG | jq -r '.fluentBitRelease')
        export FB_SERVER_OS=$(cat $SERVER_CONFIG | jq -r '.os')
        export FB_VAULT_CD_USER_FIELD=$(cat $SERVER_CONFIG | jq -r '.vault_cd_user_field')
        export FB_VAULT_CD_PASS_FIELD=$(cat $SERVER_CONFIG | jq -r '.vault_cd_pass_field')
        export FB_VAULT_CD_PATH=$(cat $SERVER_CONFIG | jq -r '.vault_cd_path')
        if [ "$FB_VAULT_CD_USER_FIELD" == "null" ] || [ "$FB_VAULT_CD_PASS_FIELD" == "null" ] || [ "$FB_VAULT_CD_PATH" == "null" ]; then
            continue
        fi
        export FB_CD_USER=$(VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN /sw_ux/bin/vault kv get -field=$FB_VAULT_CD_USER_FIELD $FB_VAULT_CD_PATH)
        export FB_CD_PASS=$(VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN /sw_ux/bin/vault kv get -field=$FB_VAULT_CD_PASS_FIELD $FB_VAULT_CD_PATH)

        if [ "$FB_RELEASE" == "null" ]; then
            export FB_RELEASE=$BASE_FB_RELEASE
        fi
        if [ "$FB_HOST" != "localhost" ] && [ "$FB_SERVER_OS" == "linux" ] ; then
            echo "$FB_HOST - target: $FB_RELEASE"
            sshpass -p $FB_CD_PASS ssh -o 'StrictHostKeyChecking=no' -q $FB_CD_USER@$FB_HOST /bin/bash <<EOF
if [ -r $FB_AGENT_ROOT ]; then
    AGENTS=\$(ls -d $FB_AGENT_ROOT/fluent-bit.* 2>/dev/null)
    if [ "\${#AGENTS[@]}" -gt 0 ]; then
        for agent in \${AGENTS[@]} ; do
            AGENT=\$(basename \$agent)
            AGENT_HOME=$FB_AGENT_ROOT/\$AGENT
            if [ -r \$AGENT_HOME ]; then
                export LD_LIBRARY_PATH="\${AGENT_HOME}/lib"
                AGENT_VERSION=\$(\$AGENT_HOME/bin/fluent-bit --version | head -1 | tr -d '\n')
                echo -n "- \$AGENT: \${AGENT_VERSION:12}"
                if [ "$FB_RELEASE" = "\${AGENT_VERSION:12}" ]; then
                    echo ""
                else
                    echo " [Out of date]"
                fi
            fi
        done
    else
        echo " - Not deployed!"
    fi
else
    echo " - Not deployed!"
fi
EOF
            if [ $? -ne 0 ]; then
                echo "- Error: Could not connect"
            fi
        fi
    done
fi

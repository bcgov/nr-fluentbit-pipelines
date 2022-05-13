#!/bin/sh
set +x

SERVER_CONFIGS=$(ls -d fb/config/server/*.json 2>/dev/null)
BASE_FB_RELEASE=$(cat fb/config/base.json | jq -r '.fluentBitRelease')
echo "Base release: $BASE_FB_RELEASE"
if [ "${#SERVER_CONFIGS[@]}" -gt 0 ]; then
    for SERVER_CONFIG in ${SERVER_CONFIGS[@]} ; do
        export HOST=$(cat $SERVER_CONFIG | jq -r '.address')
        export FB_RELEASE=$(cat $SERVER_CONFIG | jq -r '.fluentBitRelease')
        if [ -z "$FB_RELEASE" ]; then
            FB_RELEASE=$BASE_FB_RELEASE
        fi
        if [ "$HOST" != "localhost" ]; then
            echo $HOST
            sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
if [ -r $AGENT_ROOT ]; then
    AGENTS=\$(ls -d $AGENT_ROOT/fluent-bit.* 2>/dev/null)
    if [ "\${#AGENTS[@]}" -gt 0 ]; then
        for agent in \${AGENTS[@]} ; do
            AGENT=\$(basename \$agent)
            AGENT_HOME=$AGENT_ROOT/\$AGENT
            if [ -r \$AGENT_HOME ]; then
                AGENT_VERSION=\$(\$AGENT_HOME/bin/fluent-bit --version)
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

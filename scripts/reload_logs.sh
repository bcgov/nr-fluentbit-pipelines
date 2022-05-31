#!/bin/sh
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
# become run_user
if [ "$PCI" = "true" ]; then
    /sw_ux/bin/sshpass -p $CD_PASS sudo -su $RUN_USER
else
    sudo -su $RUN_USER
fi

/sw_ux/bin/sqlite3 $FLUENTBIT_DB 'update in_tail_files set offset=0 where name like "$TAIL_FILES_LIKE"'

AGENTS=\$(ls -d $AGENT_ROOT/fluent-bit.* 2>/dev/null)
if [ "\${#AGENTS[@]}" -gt 0 ]; then
    for agent in \${AGENTS[@]}; do
        AGENT=\$(basename \$agent)
        AGENT_HOME=$AGENT_ROOT/\$AGENT
        if [ -r $S6_SERVICE_HOME/\$AGENT/run ]; then
            /sw_ux/s6/bin/s6-svc -d $S6_SERVICE_HOME/\$AGENT/
        fi
    done
    sleep 5
    for agent in \${AGENTS[@]}; do
        AGENT=\$(basename \$agent)
        AGENT_HOME=$AGENT_ROOT/\$AGENT
        if [ -r $S6_SERVICE_HOME/\$AGENT/run ]; then
            /sw_ux/s6/bin/s6-svc -u $S6_SERVICE_HOME/\$AGENT/
        fi
    done
fi
EOF
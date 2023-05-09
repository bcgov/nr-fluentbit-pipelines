#!/bin/sh
set +x
sshpass -p $FB_CD_PASS ssh -q $FB_CD_USER@$FB_HOST /bin/bash <<EOF
# become FB_RUN_USER
if [ "$PCI" = "true" ]; then
    /sw_ux/bin/sshpass -p $FB_CD_PASS sudo -su $FB_RUN_USER
else
    sudo -su $FB_RUN_USER
fi

/sw_ux/bin/sqlite3 $FLUENTBIT_DB 'update in_tail_files set offset=0 where name like "$TAIL_FILES_LIKE"'

AGENTS=\$(ls -d $FB_AGENT_ROOT/fluent-bit.* 2>/dev/null)
if [ "\${#AGENTS[@]}" -gt 0 ]; then
    for agent in \${AGENTS[@]}; do
        AGENT=\$(basename \$agent)
        AGENT_HOME=$FB_AGENT_ROOT/\$AGENT
        if [ -r $FB_S6_SERVICE_HOME/\$AGENT/run ]; then
            /sw_ux/s6/bin/s6-svc -d $FB_S6_SERVICE_HOME/\$AGENT/
        fi
    done
    sleep 6
    for agent in \${AGENTS[@]}; do
        AGENT=\$(basename \$agent)
        AGENT_HOME=$FB_AGENT_ROOT/\$AGENT
        if [ -r $FB_S6_SERVICE_HOME/\$AGENT/run ]; then
            /sw_ux/s6/bin/s6-svc -o $FB_S6_SERVICE_HOME/\$AGENT/
        fi
    done
fi
EOF
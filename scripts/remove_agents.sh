#!/bin/sh
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
# remove previously deployed s6 event/supervise directories and .env file
# become run_user
if [ "$PCI" = "true" ]; then
    sshpass -p $CD_PASS sudo -su $RUN_USER
else
    sudo -su $RUN_USER
fi
AGENTS=\$(ls -d $AGENT_ROOT/fluent-bit.* 2>/dev/null)
if [ "\${#AGENTS[@]}" -gt 0 ]; then
    for agent in \${AGENTS[@]} ; do
        AGENT=\$(basename \$agent)
        AGENT_HOME=$AGENT_ROOT/\$AGENT
        if [ -r $S6_SERVICE_HOME/\$AGENT/event ]; then
            rm -rf $S6_SERVICE_HOME/\$AGENT/event
        fi
        if [ -r $S6_SERVICE_HOME/\$AGENT/supervise ]; then
            rm -rf $S6_SERVICE_HOME/\$AGENT/supervise
        fi
        # Remove .env file
        if [ -r \$AGENT_HOME/bin/.env ]; then
            rm \$AGENT_HOME/bin/.env
        fi
    done
fi
exit

# remove previously deployed s6 service directories
# become install_user
if [ "$PCI" = "true" ]; then
    sshpass -p $CD_PASS sudo -su $INSTALL_USER
else
    sudo -su $INSTALL_USER
fi
AGENTS=\$(ls -d $AGENT_ROOT/fluent-bit.* 2>/dev/null)
if [ "\${#AGENTS[@]}" -gt 0 ]; then
    for agent in \${AGENTS[@]} ; do
        AGENT=\$(basename \$agent)
        if [ -r $S6_SERVICE_HOME/\$AGENT ]; then
            rm -rf $S6_SERVICE_HOME/\$AGENT
        fi
    done
fi
exit

# Tidy up s6 services
# become run_user
if [ "$PCI" = "true" ]; then
    sshpass -p $CD_PASS sudo -su $RUN_USER
else
    sudo -su $RUN_USER
fi
/sw_ux/s6/bin/s6-svscanctl -an $S6_SERVICE_HOME
/sw_ux/s6/bin/s6-svscanctl -z $S6_SERVICE_HOME
exit

# remove previously deployed agents
# become install_user
if [ "$PCI" = "true" ]; then
    sshpass -p $CD_PASS sudo -su $INSTALL_USER
else
    sudo -su $INSTALL_USER
fi
AGENTS=\$(ls -d $AGENT_ROOT/fluent-bit.* 2>/dev/null)
if [ "\${#AGENTS[@]}" -gt 0 ]; then
    for agent in \${AGENTS[@]} ; do
        AGENT=\$(basename \$agent)
        AGENT_HOME=$AGENT_ROOT/\$AGENT
        if [ -r \$AGENT_HOME ]; then
            rm -rf \$AGENT_HOME
        fi
    done
fi
EOF

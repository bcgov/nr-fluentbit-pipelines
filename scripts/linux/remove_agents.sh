#!/usr/bin/env bash
set +x
sshpass -p $FB_CD_PASS ssh -o 'StrictHostKeyChecking=no' -q $FB_CD_USER@$FB_HOST /bin/bash <<EOF
# remove previously deployed s6 event/supervise directories and .env file
sudo -su $FB_RUN_USER
AGENTS=\$(ls -d $FB_AGENT_ROOT/fluent-bit.* 2>/dev/null)
if [ "\${#AGENTS[@]}" -gt 0 ]; then
    for agent in \${AGENTS[@]} ; do
        AGENT=\$(basename \$agent)
        AGENT_HOME=$FB_AGENT_ROOT/\$AGENT
        if [ -r $FB_S6_SERVICE_HOME/\$AGENT/event ]; then
            rm -rf $FB_S6_SERVICE_HOME/\$AGENT/event
        fi
        if [ -r $FB_S6_SERVICE_HOME/\$AGENT/supervise ]; then
            rm -rf $FB_S6_SERVICE_HOME/\$AGENT/supervise
        fi
        # Remove .env file
        if [ -r \$AGENT_HOME/bin/.env ]; then
            rm \$AGENT_HOME/bin/.env
        fi
    done
fi
exit

# remove previously deployed s6 service directories
sudo -su $FB_INSTALL_USER
AGENTS=\$(ls -d $FB_AGENT_ROOT/fluent-bit.* 2>/dev/null)
if [ "\${#AGENTS[@]}" -gt 0 ]; then
    for agent in \${AGENTS[@]} ; do
        AGENT=\$(basename \$agent)
        if [ -r $FB_S6_SERVICE_HOME/\$AGENT ]; then
            rm -rf $FB_S6_SERVICE_HOME/\$AGENT
        fi
    done
fi
exit

# Tidy up s6 services
# become FB_RUN_USER
if [ "$PCI" = "true" ]; then
    /sw_ux/bin/sshpass -p $FB_CD_PASS sudo -su $FB_RUN_USER
else
    sudo -su $FB_RUN_USER
fi
/sw_ux/s6/bin/s6-svscanctl -an $FB_S6_SERVICE_HOME
/sw_ux/s6/bin/s6-svscanctl -z $FB_S6_SERVICE_HOME
exit

# remove previously deployed agents
# become FB_INSTALL_USER
if [ "$PCI" = "true" ]; then
    /sw_ux/bin/sshpass -p $FB_CD_PASS sudo -su $FB_INSTALL_USER
else
    sudo -su $FB_INSTALL_USER
fi
AGENTS=\$(ls -d $FB_AGENT_ROOT/fluent-bit.* 2>/dev/null)
if [ "\${#AGENTS[@]}" -gt 0 ]; then
    for agent in \${AGENTS[@]} ; do
        AGENT=\$(basename \$agent)
        AGENT_HOME=$FB_AGENT_ROOT/\$AGENT
        if [ -r \$AGENT_HOME ]; then
            rm -rf \$AGENT_HOME
        fi
    done
fi
EOF

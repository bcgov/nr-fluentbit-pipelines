#!/bin/sh
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF

# remove previously deployed s6 event/supervise directories
sudo -su wwwsvr
AGENTS=\$(ls -d $AGENT_ROOT/fluent-bit.*)
for agent in \${AGENTS[@]} ; do
    AGENT=\$(basename \$agent)
    if [ -r $S6_SERVICE_HOME/\$AGENT/event ]; then
        rm -rf $S6_SERVICE_HOME/\$AGENT/event
    fi
    if [ -r $S6_SERVICE_HOME/\$AGENT/supervise ]; then
        rm -rf $S6_SERVICE_HOME/\$AGENT/supervise
    fi
done
exit

# remove previously deployed s6 service directories
sudo -su wwwadm
AGENTS=\$(ls -d $AGENT_ROOT/fluent-bit.*)
for agent in \${AGENTS[@]} ; do
    AGENT=\$(basename \$agent)
    if [ -r $S6_SERVICE_HOME/\$AGENT ]; then
        rm -rf $S6_SERVICE_HOME/\$AGENT
    fi
    if [ -r $S6_SERVICE_HOME/\$AGENT ]; then
        rm -rf $S6_SERVICE_HOME/\$AGENT
    fi
done

# remove previously deployed agents
for agent in \${AGENTS[@]} ; do
    AGENT=\$(basename \$agent)
    AGENT_HOME=$AGENT_ROOT/\$AGENT
    if [ -r \$AGENT_HOME ]; then
        rm -rf \$AGENT_HOME
    fi
done

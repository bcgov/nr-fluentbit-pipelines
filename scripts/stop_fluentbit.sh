#!/bin/sh
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
# become wwwsvr
sudo -su wwwsvr

AGENTS=\$(ls -d $AGENT_ROOT/fluent-bit.*)
for agent in \${AGENTS[@]} ; do
    AGENT=\$(basename \$agent)
    if [ -r $S6_SERVICE_HOME/\$AGENT/run ]; then
        /sw_ux/s6/bin/s6-svc -d $S6_SERVICE_HOME/\$AGENT/
    fi
done
sleep 5
EOF
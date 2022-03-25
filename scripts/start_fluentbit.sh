#!/bin/sh
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
# become wwwsvr
sudo -su wwwsvr
# set temp directory
TMP_DIR="$TMP_DIR"
echo "Temp directory: \$TMP_DIR"
# get agents
cd \$TMP_DIR
echo "Working directory: \$(pwd)"
AGENTS=\$(ls -d output/fluent-bit.*)
for agent in \${AGENTS[@]} ; do
    AGENT=\$(basename \$agent)
    if [ -r /apps_ux/s6_services/\$AGENT/run ]; then
        /sw_ux/s6/bin/s6-svc -u /apps_ux/s6_services/\$AGENT/
    fi
    sleep 5
done
exit
echo "Current user: \$(whoami)"
# set temp directory
TMP_DIR="$TMP_DIR"
rm -rf \$TMP_DIR
EOF
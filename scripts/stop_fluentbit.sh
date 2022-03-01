#!/bin/sh
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
# become wwwsvr
sudo -su wwwsvr
if [ -r $S6_SERVICE_DIR/run ]; then
    /sw_ux/s6/bin/s6-svc -d /apps_ux/s6_services/fluent-bit/
fi
sleep 5
EOF
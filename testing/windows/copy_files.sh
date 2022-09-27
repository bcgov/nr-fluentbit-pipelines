#!/usr/bin/env bash
set +x
export CD_USER=$(vault kv get -field=username_domainless groups/appdelivery/oraapp_imborapp)
export CD_PASS=$(vault kv get -field=password groups/appdelivery/oraapp_imborapp)
export TMP_DIR="E:/tmp/fluent-bit.testing"
export HOST="stress.dmz"
export FUNBUCKS_OUTPUT="/home/andrwils/projects/BCGOV-NR/nr-funbucks/output"

sshpass -p $CD_PASS ssh -q $CD_USER@$HOST powershell.exe -Command -<<EOF
New-Item -ItemType "directory" -Path "$TMP_DIR" -Force
New-Item -ItemType "directory" -Path "$TMP_DIR/bin" -Force
EOF

sshpass -p $CD_PASS scp -q -r ../../files $CD_USER@$HOST:$TMP_DIR
sshpass -p $CD_PASS scp -q -r $FUNBUCKS_OUTPUT $CD_USER@$HOST:$TMP_DIR

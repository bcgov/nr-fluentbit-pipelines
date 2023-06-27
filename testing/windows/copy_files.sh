#!/usr/bin/env bash
set +x
export CD_USER=$(vault kv get -field=username_domainless groups/appdelivery/oraapp_imborapp)
export CD_PASS=$(vault kv get -field=password groups/appdelivery/oraapp_imborapp)
export FB_TMP_DIR="E:/tmp/fluent-bit.testing"
export HOST="stress.dmz"
export FUNBUCKS_OUTPUT="/home/andrwils/projects/BCGOV-NR/nr-funbucks/output"

sshpass -p $FB_CD_PASS ssh -q $FB_CD_USER@$FB_HOST powershell.exe -Command -<<EOF
New-Item -ItemType "directory" -Path "$FB_TMP_DIR" -Force
New-Item -ItemType "directory" -Path "$FB_TMP_DIR/bin" -Force
EOF

sshpass -p $FB_CD_PASS scp -q -r ../../files $FB_CD_USER@$FB_HOST:$FB_TMP_DIR
sshpass -p $FB_CD_PASS scp -q -r $FB_FUNBUCKS_OUTPUT $FB_CD_USER@$FB_HOST:$FB_TMP_DIR

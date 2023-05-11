#!/usr/bin/env bash
set +x
sshpass -p $FB_CD_PASS ssh -o 'StrictHostKeyChecking=no' -q $FB_CD_USER@$FB_HOST powershell.exe -Command -<<EOF
New-Item -ItemType "directory" -Path "$FB_TMP_DIR" -Force
New-Item -ItemType "directory" -Path "$FB_TMP_DIR/bin" -Force
EOF

sshpass -p $FB_CD_PASS scp -o 'StrictHostKeyChecking=no' -q -r files $FB_CD_USER@$FB_HOST:$FB_TMP_DIR
sshpass -p $FB_CD_PASS scp -o 'StrictHostKeyChecking=no' -q -r $FB_FUNBUCKS_OUTPUT $FB_CD_USER@$FB_HOST:$FB_TMP_DIR

#!/usr/bin/env bash
set +x
sshpass -p $FB_CD_PASS ssh -F /app/ssh-config -q $FB_CD_USER@$FB_HOST powershell.exe -Command -<<EOF
New-Item -ItemType "directory" -Path "$FB_TMP_DIR" -Force
New-Item -ItemType "directory" -Path "$FB_TMP_DIR/bin" -Force
EOF

sshpass -p $FB_CD_PASS scp -F /app/ssh-config -q -r files $FB_CD_USER@$FB_HOST:$FB_TMP_DIR
sshpass -p $FB_CD_PASS scp -F /app/ssh-config -q -r $FB_FUNBUCKS_OUTPUT $FB_CD_USER@$FB_HOST:$FB_TMP_DIR

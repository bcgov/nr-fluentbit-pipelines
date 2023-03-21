#!/usr/bin/env bash
set +x
sshpass -p $CD_PASS ssh -o 'StrictHostKeyChecking=no' -q $CD_USER@$HOST powershell.exe -Command -<<EOF
New-Item -ItemType "directory" -Path "$TMP_DIR" -Force
New-Item -ItemType "directory" -Path "$TMP_DIR/bin" -Force
EOF

sshpass -p $CD_PASS scp -q -r files $CD_USER@$HOST:$TMP_DIR
sshpass -p $CD_PASS scp -q -r $FUNBUCKS_OUTPUT $CD_USER@$HOST:$TMP_DIR

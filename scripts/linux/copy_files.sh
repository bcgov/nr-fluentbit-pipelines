#!/usr/bin/env bash
set +x
sshpass -p $FB_CD_PASS ssh -F /app/ssh-config -q $FB_CD_USER@$FB_HOST /bin/bash <<EOF
# become FB_INSTALL_USER
sudo -su $FB_INSTALL_USER

mkdir $FB_TMP_DIR
mkdir $FB_TMP_DIR/bin
mkdir $FB_TMP_DIR/backup
chmod -R 777 $FB_TMP_DIR
EOF

sshpass -p $FB_CD_PASS scp -F /app/ssh-config -q -r files $FB_CD_USER@$FB_HOST:$FB_TMP_DIR
sshpass -p $FB_CD_PASS scp -F /app/ssh-config -q -r $FB_FUNBUCKS_OUTPUT $FB_CD_USER@$FB_HOST:$FB_TMP_DIR
sshpass -p $FB_CD_PASS ssh -F /app/ssh-config -q $FB_CD_USER@$FB_HOST /bin/bash <<EOF
chmod -R 777 $FB_TMP_DIR/files
chmod -R 777 $FB_TMP_DIR/output
EOF

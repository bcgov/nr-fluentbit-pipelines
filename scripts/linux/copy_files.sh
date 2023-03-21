#!/usr/bin/env bash
set +x
sshpass -p $CD_PASS ssh -o 'StrictHostKeyChecking=no' -q $CD_USER@$HOST /bin/bash <<EOF
# become install_user
sudo -su $INSTALL_USER

mkdir $TMP_DIR
mkdir $TMP_DIR/bin
mkdir $TMP_DIR/backup
chmod -R 777 $TMP_DIR
EOF

sshpass -p $CD_PASS scp -q -r files $CD_USER@$HOST:$TMP_DIR
sshpass -p $CD_PASS scp -q -r $FUNBUCKS_OUTPUT $CD_USER@$HOST:$TMP_DIR
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
chmod -R 777 $TMP_DIR/files
chmod -R 777 $TMP_DIR/output
EOF

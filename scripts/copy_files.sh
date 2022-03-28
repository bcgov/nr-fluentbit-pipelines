#!/bin/sh
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
# become wwwadm
sudo -su wwwadm
mkdir $TMP_DIR
mkdir $TMP_DIR/bin
mkdir $TMP_DIR/backup
chmod -R 775 $TMP_DIR
EOF
sshpass -p $CD_PASS scp -q -r files $CD_USER@$HOST:$TMP_DIR
sshpass -p $CD_PASS scp -q -r $FUNBUCKS_OUTPUT $CD_USER@$HOST:$TMP_DIR

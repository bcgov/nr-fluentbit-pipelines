#!/bin/sh
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
# become install_user
if [ "$PCI" = "true" ]; then
    sshpass -p $CD_PASS sudo -su $INSTALL_USER
else
    sudo -su $INSTALL_USER
fi
mkdir $TMP_DIR
mkdir $TMP_DIR/bin
mkdir $TMP_DIR/backup
chmod -R 777 $TMP_DIR
EOF

sshpass -p $CD_PASS scp -q -r files $CD_USER@$HOST:$TMP_DIR
sshpass -p $CD_PASS scp -q -r $FUNBUCKS_OUTPUT $CD_USER@$HOST:$TMP_DIR
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
# if PCI, the files and output directories will be owned by your account, so we need to set the permissions so the files can be cleaned up
# become install_user
if [ "$PCI" = "true" ]; then
    chmod -R 777 $TMP_DIR/files
    chmod -R 777 $TMP_DIR/output
else
    sudo -su $INSTALL_USER
    chmod -R 777 $TMP_DIR/files
    chmod -R 777 $TMP_DIR/output
fi
EOF

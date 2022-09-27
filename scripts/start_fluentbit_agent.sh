#!/bin/sh
set +x

SERVER_IP=$(dig +short $HOST | tail -n1)

sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
# become run_user
if [ "$PCI" = "true" ]; then
    /sw_ux/bin/sshpass -p $CD_PASS sudo -su $RUN_USER
else
    sudo -su $RUN_USER
fi

# extract interface name
METRIC_HOST_NETWORK_INTERFACE_NAME=\$(ip addr | awk '
/^[0-9]+:/ {
  sub(/:/,"",\$2); iface=\$2 }
/^[[:space:]]*inet / {
  split(\$2, a, "/")
  print iface" : "a[1]
}' | grep $SERVER_IP | sed 's/\\s.*//g')

FB_SECRET_ID=\$(set +x; VAULT_ADDR=$VAULT_ADDR /sw_ux/bin/vault unwrap -field=secret_id $WRAPPED_FB_SECRET_ID)

# if $AGENT defined, deploy one; else deploy all in the list
if [ -z \$AGENT ] ; then
  AGENTS=\$(ls -d $AGENT_ROOT/fluent-bit.*)
else
  AGENTS=(\$AGENT)
fi

for agent in \${AGENTS[@]} ; do
  AGENT=\$(basename \$agent)

  AGENT_HOME=$AGENT_ROOT/\$AGENT
  # revoke previous token
  if [ -r \$AGENT_HOME/bin/.env ]; then
      echo "Attempting to revoke previous token..."
      PREVIOUS_TOKEN=\$(cat \$AGENT_HOME/bin/.env | grep VAULT_TOKEN | awk -F '"' '{print \$2}')
      VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=\$PREVIOUS_TOKEN /sw_ux/bin/vault token revoke -self
  fi
  # generate and deploy new app token to .env file
  APP_TOKEN=\$(set +x; VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN /sw_ux/bin/vault write -force -field=token auth/vs_apps_approle/login role_id=$FB_ROLE_ID secret_id=\$FB_SECRET_ID)
  sed 's/VAULT_TOKEN=.*/'VAULT_TOKEN=\""\$APP_TOKEN"\"'/g;s/METRIC_HOST_NETWORK_INTERFACE_NAME=.*/'METRIC_HOST_NETWORK_INTERFACE_NAME=\""\$METRIC_HOST_NETWORK_INTERFACE_NAME"\"'/g' \$AGENT_HOME/bin/.env.template > \$AGENT_HOME/bin/.env
  chmod 700 \$AGENT_HOME/bin/.env
  if [ -r $S6_SERVICE_HOME/$AGENT/run ]; then
      AGENT_UP=\$(/sw_ux/s6/bin/s6-svstat -o up $S6_SERVICE_HOME/$AGENT/)
      if [ "\$AGENT_UP" = "true" ]; then
        # s6 is too old on some servers to do this
        #echo "Stopping agent with: /sw_ux/s6/bin/s6-svc -d $S6_SERVICE_HOME/$AGENT/"
        #/sw_ux/s6/bin/s6-svc -d $S6_SERVICE_HOME/$AGENT/
        echo "Stopping agent with: /sw_ux/s6/bin/s6-svc -i $S6_SERVICE_HOME/$AGENT/"
        /sw_ux/s6/bin/s6-svc -i $S6_SERVICE_HOME/$AGENT/
        for (( c = 0; c < 6; c++ ))
        do
          AGENT_UP=\$(/sw_ux/s6/bin/s6-svstat -o up $S6_SERVICE_HOME/$AGENT/)
          if [ "\$AGENT_UP" = "false" ]; then
            break
          fi
          sleep 1
        done
      fi
      /sw_ux/s6/bin/s6-svc -o $S6_SERVICE_HOME/$AGENT/
  fi
done
EOF
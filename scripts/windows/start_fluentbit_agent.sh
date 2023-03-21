#!/usr/bin/env bash
set +x

sshpass -p $CD_PASS ssh -o 'StrictHostKeyChecking=no' -q $CD_USER@$HOST powershell.exe -Command -<<EOF
\$env:VAULT_ADDR = "$VAULT_ADDR"
\$env:VAULT_TOKEN = "\$VAULT_TOKEN"
\$env:FB_SECRET_ID = ($BIN_DIR/vault/vault.exe unwrap -field=secret_id $WRAPPED_FB_SECRET_ID)

# if $AGENT defined, deploy one; else deploy all in the list
if ("$AGENT".Length -eq 0) {
  \$AGENTS = (Get-ChildItem -Directory -Path "$AGENT_ROOT/fluent-bit.*" -Name)
} else {
  \$AGENTS=("$AGENT")
}

if (\$AGENTS.count -gt 0) {
  Foreach (\$i in \$AGENTS) {
    \$AGENT = \$i
    echo "Agent: \$AGENT"
    \$AGENT_HOME = "$AGENT_ROOT/\$AGENT"
    # revoke previous token
    if (Test-Path -Path "\$AGENT_HOME/bin/\$AGENT.xml" -PathType Leaf) {
      echo "Attempting to revoke previous token..."
      \$PREVIOUS_TOKEN = Select-String -Path "\$AGENT_HOME/bin/\${AGENT}.xml" -Pattern '(hvs\.[\D\d][^"]+)' | %{\$_.matches.value}
      \$env:VAULT_TOKEN = "\$PREVIOUS_TOKEN"
      $BIN_DIR/vault/vault.exe token revoke -self
    }
    # generate and deploy new app token to WinSW service configuration file
    \$env:VAULT_TOKEN = "\$VAULT_TOKEN"
    \$APP_TOKEN = ($BIN_DIR/vault/vault.exe write -force -field=token auth/vs_apps_approle/login role_id=$FB_ROLE_ID secret_id=\$env:FB_SECRET_ID)
    Get-Content "\$AGENT_HOME/bin/\${AGENT}.xml" | % { 
      \$_ -replace '({{vault_template_token}})|(hvs\.[\D\d][^"]+)',"\$APP_TOKEN"} | Set-Content "\$AGENT_HOME/bin/\${AGENT}.xml.bak" -Force
    Copy-Item -Path "\$AGENT_HOME/bin/\${AGENT}.xml.bak" -Destination "\$AGENT_HOME/bin/\${AGENT}.xml" -Force
    # start agent
    Start-Service \$AGENT
    }
} else {
  echo "No agents found"
}

EOF

#!/usr/bin/env bash
set +x
export CD_USER=$(vault kv get -field=username_domainless groups/appdelivery/oraapp_imborapp)
export CD_PASS=$(vault kv get -field=password groups/appdelivery/oraapp_imborapp)
export HOST="stress.dmz"
export FB_AGENT_ROOT="E:/apps_nt/agents"
export VAULT_ADDR="https://vault-iit.apps.silver.devops.gov.bc.ca"
export VAULT_HOME="E:/sw_nt/vault"

sshpass -p $FB_CD_PASS ssh -q $FB_CD_USER@$FB_HOST powershell.exe -Command -<<EOF
\$AGENTS = (Get-ChildItem -Directory -Path $FB_AGENT_ROOT/fluent-bit.* -Name)

# note the extra space after the loop
# required to execute
if (\$AGENTS.count -gt 0) {
  Foreach (\$i in \$AGENTS) {
    \$AGENT = \$i
    echo "Agent: \$AGENT"
    \$AGENT_HOME = "$FB_AGENT_ROOT/\$AGENT"
    # revoke previous token
    if (Test-Path -Path "\$AGENT_HOME/bin/\$AGENT.xml" -PathType Leaf) {
      echo "Attempting to revoke previous token..."
      \$PREVIOUS_TOKEN = Select-String -Path "\$AGENT_HOME/bin/\${AGENT}.xml" -Pattern '(hvs\.[\D\d][^"]+)' | %{\$_.matches.value}
      \$env:VAULT_ADDR = "$VAULT_ADDR"
      \$env:VAULT_TOKEN = "\$PREVIOUS_TOKEN"
      $VAULT_HOME/vault.exe token revoke -self
    }
    Stop-Service \$AGENT
  }
} else {
  echo "No agents found"
}

EOF

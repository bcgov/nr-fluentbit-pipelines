#!/usr/bin/env bash
set +x

sshpass -p $FB_CD_PASS ssh -F /app/ssh-config -q $FB_CD_USER@$FB_HOST powershell.exe -Command -<<EOF
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
      $FB_BIN_DIR/vault/vault.exe token revoke -self
    }
    Stop-Service \$AGENT
  }
} else {
  echo "No agents found"
}

EOF

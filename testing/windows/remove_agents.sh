#!/usr/bin/env bash
set +x
export CD_USER=$(vault kv get -field=username_domainless groups/appdelivery/oraapp_imborapp)
export CD_PASS=$(vault kv get -field=password groups/appdelivery/oraapp_imborapp)
export HOST="stress.dmz"
export FB_AGENT_ROOT="E:/apps_nt/agents"

sshpass -p $FB_CD_PASS ssh -q $FB_CD_USER@$FB_HOST powershell.exe -Command -<<EOF
# remove previously deployed WinSW services and fluent bit configuration
\$AGENTS = (Get-ChildItem -Directory -Path $FB_AGENT_ROOT/fluent-bit.* -Name)

# note the extra space after the loop
# required to execute
if (\$AGENTS.count -gt 0) {
  Foreach (\$i in \$AGENTS) {
    \$AGENT = \$i
    \$AGENT_HOME = "$FB_AGENT_ROOT/\$AGENT"
    # remove service
    Invoke-Expression -Command "\$AGENT_HOME/bin/\${AGENT}.exe uninstall \$AGENT_HOME/bin/\${AGENT}.xml"
    # remove fluent bit config
    Remove-Item -Path "\$AGENT_HOME" -Recurse
    }
} else {
  echo "No agents found"
}

EOF

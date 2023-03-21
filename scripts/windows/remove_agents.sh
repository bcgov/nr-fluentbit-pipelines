#!/usr/bin/env bash
set +x

sshpass -p $CD_PASS ssh -o 'StrictHostKeyChecking=no' -q $CD_USER@$HOST powershell.exe -Command -<<EOF
# remove previously deployed WinSW services and fluent bit configuration
\$AGENTS = (Get-ChildItem -Directory -Path $AGENT_ROOT/fluent-bit.* -Name)

# note the extra space after the loop
# required to execute
if (\$AGENTS.count -gt 0) {
  Foreach (\$i in \$AGENTS) {
    \$AGENT = \$i
    \$AGENT_HOME = "$AGENT_ROOT/\$AGENT"
    # remove service
    Invoke-Expression -Command "\$AGENT_HOME/bin/\${AGENT}.exe uninstall \$AGENT_HOME/bin/\${AGENT}.xml"
    # remove fluent bit config
    Remove-Item -Path "\$AGENT_HOME" -Recurse
    }
} else {
  echo "No agents found"
}

EOF

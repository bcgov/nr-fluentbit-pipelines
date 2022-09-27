#!/usr/bin/env bash
set +x
export CD_USER=$(vault kv get -field=username_domainless groups/appdelivery/oraapp_imborapp)
export CD_PASS=$(vault kv get -field=password groups/appdelivery/oraapp_imborapp)
export HOST="stress.dmz"
export FLUENTBIT_RELEASE="1.9.6"
export TMP_DIR="E:/tmp/fluent-bit.testing"
export BIN_DIR="E:/sw_nt"
export AGENT_ROOT="E:/apps_nt/agents"
export HTTP_PROXY=""
export VAULT_RELEASE="1.10.4"
export ENVCONSUL_RELEASE="0.12.1"
export JQ_RELEASE="1.6"
export SQLITE_RELEASE="3.38.5"
export WINSW_RELEASE="v2.11.0"

sshpass -p $CD_PASS ssh -q $CD_USER@$HOST powershell.exe -Command -<<EOF
echo "Temp directory: $TMP_DIR"
\$AGENTS = (Get-ChildItem -Directory -Path "$TMP_DIR/output/fluent-bit.*" -Name)

if (\$AGENTS.count -gt 0) {
  Foreach (\$i in \$AGENTS) {
    \$AGENT = \$i
    \$AGENT_HOME = "$AGENT_ROOT/\$AGENT"
    # copy WinSW service wrapper and generate service configuration file
    Copy-Item -Path "$TMP_DIR/bin/WinSW-x64.exe" -Destination "\$AGENT_HOME/bin/\${AGENT}.exe" -Force
    Get-Content "$TMP_DIR/files/fluent-bit.xml" | % { 
      \$_.replace("{{fluent_version}}","$FLUENTBIT_RELEASE").
      replace("{{agent}}","\$AGENT").
      replace("{{fluent_conf_home}}","$AGENT_ROOT/\$AGENT/conf").
      replace("{{bin_dir}}", "$BIN_DIR").
      replace("{{agent_root}}", "$AGENT_ROOT")
    } | Set-Content "\$AGENT_HOME/bin/\${AGENT}.xml" -Force
    Get-Content "$TMP_DIR/files/run_fluentbit.bat" | % { \$_.replace("{{agent}}","\$AGENT") } | Set-Content "\$AGENT_HOME/bin/run_fluentbit.bat" -Force
    # install service
    Invoke-Expression -Command "\$AGENT_HOME/bin/\${AGENT}.exe install \$AGENT_HOME/bin/\${AGENT}.xml"
  }  
} else {
  throw "No agents found for deployment"
}

EOF

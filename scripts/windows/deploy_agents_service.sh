#!/usr/bin/env bash
set +x

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
    # install service
    Invoke-Expression -Command "\$AGENT_HOME/bin/\${AGENT}.exe install \$AGENT_HOME/bin/\${AGENT}.xml"
  }  
} else {
  throw "No agents found for deployment"
}

# clean up
Remove-Item -Path "$TMP_DIR" -Recurse

EOF

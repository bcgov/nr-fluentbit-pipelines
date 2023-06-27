#!/usr/bin/env bash
set +x

sshpass -p $FB_CD_PASS ssh -o 'StrictHostKeyChecking=no' -q $FB_CD_USER@$FB_HOST powershell.exe -Command -<<EOF
echo "Temp directory: $FB_TMP_DIR"
\$AGENTS = (Get-ChildItem -Directory -Path "$FB_TMP_DIR/output/fluent-bit.*" -Name)

if (\$AGENTS.count -gt 0) {
  Foreach (\$i in \$AGENTS) {
    \$AGENT = \$i
    \$AGENT_HOME = "$FB_AGENT_ROOT/\$AGENT"
    # copy WinSW service wrapper and generate service configuration file
    Copy-Item -Path "$FB_TMP_DIR/bin/WinSW-x64.exe" -Destination "\$AGENT_HOME/bin/\${AGENT}.exe" -Force
    Get-Content "$FB_TMP_DIR/files/fluent-bit.xml" | % { 
      \$_.replace("{{fluent_version}}","$FB_FLUENTBIT_RELEASE").
      replace("{{agent}}","\$AGENT").
      replace("{{fluent_conf_home}}","$FB_AGENT_ROOT/\$AGENT/conf").
      replace("{{bin_dir}}", "$FB_BIN_DIR").
      replace("{{agent_root}}", "$FB_AGENT_ROOT")
    } | Set-Content "\$AGENT_HOME/bin/\${AGENT}.xml" -Force
    # install service
    Invoke-Expression -Command "\$AGENT_HOME/bin/\${AGENT}.exe install \$AGENT_HOME/bin/\${AGENT}.xml"
  }  
} else {
  throw "No agents found for deployment"
}

# clean up
Remove-Item -Path "$FB_TMP_DIR" -Recurse

EOF

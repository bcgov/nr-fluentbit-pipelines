#!/bin/sh
set +x

if [ -f "workflow-cli.zip" ]; then
    echo "CLI exists. Clear workspace to redownload workflow cli."
else
  /bin/curl -u $PIPELINE_ARTIFACTORY_CREDS_USR:$PIPELINE_ARTIFACTORY_CREDS_PSW -sSL "http://bwa.nrs.gov.bc.ca/int/artifactory/ext-binaries-local/automation/workflow/1.0.0/workflow-cli.zip" -o workflow-cli.zip
  unzip workflow-cli.zip
fi

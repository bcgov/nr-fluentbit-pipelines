vault {
  address = "https://vault-iit.apps.silver.devops.gov.bc.ca"
  renew_token = true
  retry {
    enabled = true
    attempts = 12
    backoff = "250ms"
    max_backoff = "1m"
  }
}

secret {
    no_prefix = true
    path = "apps/prod/fluent/fluent-bit"
}

exec {
  command = "{{ apm_agent_home }}/bin/fluent-bit -c {{ apm_agent_home }}/conf/fluent-bit.conf"
  splay = "5s"
  env {
    pristine = false
    custom = ["HTTP_PROXY=$HTTP_PROXY","NO_PROXY=https://vault-iit.apps.silver.devops.gov.bc.ca,169.254.169.254"]
  }
  kill_timeout = "5s"
}

pid_file = "{{ apm_agent_home }}/bin/pid"

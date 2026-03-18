vault {
  address = "https://knox.io.nrs.gov.bc.ca"
  retry {
    enabled = true
    attempts = 12
    backoff = "250ms"
    max_backoff = "1m"
  }
}

auto_auth {
  method "token_file" {
    config = {
      token_file_path = "{{ apm_agent_home }}/bin/.token"
    }
  }
}

template_config {
  exit_on_retry_failure = true
}

env_template "AWS_ACCESS_KEY_ID" {
  contents             = "{{ with secret \"apps/prod/apm/apm-onpremise-agent/aws-ssm-sync/kinesis\" }}{{ .Data.data.AWS_ACCESS_KEY_ID }}{{ end }}"
  error_on_missing_key = true
}

env_template "AWS_SECRET_ACCESS_KEY" {
  contents             = "{{ with secret \"apps/prod/apm/apm-onpremise-agent/aws-ssm-sync/kinesis\" }}{{ .Data.data.AWS_SECRET_ACCESS_KEY }}{{ end }}"
  error_on_missing_key = true
}

env_template "AWS_KINESIS_ROLE_ARN" {
  contents             = "{{ with secret \"apps/prod/apm/apm-onpremise-agent/aws-ssm-sync/kinesis\" }}{{ .Data.data.AWS_KINESIS_ROLE_ARN }}{{ end }}"
  error_on_missing_key = true
}

exec {
  command                   = ["{{ apm_agent_home }}/bin/fluentbitw"]
  restart_on_secret_changes = "always"
  restart_stop_signal       = "SIGTERM"
}

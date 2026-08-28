# Monitoring Module

## Overview

This module runs the **custom monitoring scripts** for the Grafana stack. A single
AWS Lambda is invoked by multiple EventBridge schedule rules (cron/rate); each rule
tells the Lambda which script to run. The scripts push metrics into the stack's
**Prometheus Pushgateway** (port `9091`), which Prometheus already scrapes, so the
data lands in Grafana without any new metrics pipeline.

It exists so the team can add a monitor by dropping a Python file in
`monitoring-scripts/` + one entry in `monitoring_jobs` — no Lambda redeploy.

## Architecture

```mermaid
flowchart TD
    subgraph S3["S3: monitoring-scripts-<account>-<env>"]
        SCRIPTS[check_*.py]
    end

    EB[EventBridge schedule rules] -->|{"script","job"}| LAM[Monitoring Lambda<br/>in VPC private subnets]
    LAM -->|downloads| SCRIPTS
    LAM -->|runs as subprocess| SCRIPTS
    SCRIPTS -->|monitoring_sdk| PG[Pushgateway :9091]
    PG --> PROM[Prometheus scrapes]
    PROM --> GRAF[Grafana]

    LAM -->|monitoring_run_status<br/>heartbeat| PG
    ALM[CloudWatch alarms] -.alerts on.-> LAM
```

## Resources Created

| Resource | Why it exists |
|----------|---------------|
| `aws_s3_bucket.scripts` | Stores the monitoring scripts uploaded by CI; the Lambda fetches the one named in the event at runtime (avoids baking scripts into the Lambda). |
| `aws_s3_bucket_versioning.scripts` | Recoverable, auditable script uploads. |
| `aws_s3_bucket_server_side_encryption_configuration.scripts` | Encrypts executable code at rest. |
| `aws_s3_bucket_public_access_block.scripts` | Ensures the code bucket is never publicly readable. |
| `aws_lambda_layer_version.sdk` | Publishes the shared `monitoring_sdk` package so every script can `from monitoring_sdk import Pushgateway`. |
| `aws_security_group.lambda` | Dedicated SG for the Lambda; egress to S3/AWS APIs via NAT. |
| `aws_security_group_rule.pushgateway_ingress` | Opens `:9091` from the Lambda SG into the Pushgateway SG. |
| `aws_lambda_function.monitoring` | The single dispatcher Lambda. |
| `aws_iam_role.lambda` (+ policies) | Execution role: VPC access, logs, read of the scripts bucket, and read-only AWS API access. |
| `aws_cloudwatch_event_rule.job` / `..._target` / `aws_lambda_permission.allow_events` | One scheduled trigger per monitor; fan-out to the same Lambda. |
| `aws_cloudwatch_metric_alarm.lambda_*` | Alarms so the monitoring system itself is observable (errors, throttles, no invocations). |

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `project_name` | `string` | – | Prefix for resource names |
| `env_subfix` | `string` | – | Environment suffix |
| `region` | `string` | `us-east-1` | AWS region |
| `aws_account_id` | `string` | – | Account ID (used for the S3 bucket name) |
| `vpc_id` | `string` | – | VPC hosting the Pushgateway |
| `private_subnet_ids` | `list(string)` | – | Subnets for the Lambda (need NAT for S3/AWS APIs) |
| `pushgateway_security_group_id` | `string` | – | SG protecting the Pushgateway; we open `:9091` into it |
| `pushgateway_url` | `string` | `http://pushgateway.monitoring:9091` | Pushgateway URL (Service Connect DNS) |
| `lambda_runtime` | `string` | `python3.12` | Lambda runtime |
| `lambda_policy_json` | `string` | read-only set | IAM policy JSON for the AWS APIs the monitors read |
| `alarm_actions` | `list(string)` | `[]` | SNS/topic ARNs to notify on alarm |
| `missed_run_period` | `number` | `86400` | Window (s) requiring ≥1 invocation (dead-schedule alarm) |
| `tags_project` | `map(string)` | `{}` | Common tags |
| `monitoring_jobs` | `list(object)` | `[]` | The monitors: each becomes an EventBridge schedule rule |

## Outputs

| Output | Description |
|--------|-------------|
| `lambda_function_arn` | ARN of the monitoring Lambda |
| `lambda_function_name` | Name of the monitoring Lambda |
| `lambda_layer_arn` | ARN of the shared SDK layer |
| `scripts_bucket_name` | S3 bucket holding the scripts |
| `scripts_bucket_arn` | ARN of the scripts bucket |

## Usage

```hcl
module "monitoring" {
  source = "../../modules/monitoring"

  project_name                 = var.project_name
  env_subfix                   = var.env_subfix
  region                       = var.region
  aws_account_id               = var.aws_account_id
  vpc_id                       = module.vpc.vpc_id
  private_subnet_ids           = module.vpc.private_subnet_ids
  pushgateway_security_group_id = module.security.ecs_security_group_id
  pushgateway_url              = "http://pushgateway.${module.ecs.service_discovery_namespace_name}:9091"
  tags_project                 = var.tags_project

  monitoring_jobs = [
    {
      name        = "github-status"
      script      = "check_github_status"
      job         = "github-status"
      schedule    = "cron(0 * * * ? *)"
      description = "Monitor GitHub status page + API reachability"
    },
  ]
}
```

## How to add a new monitor

1. Add `monitoring-scripts/check_my_thing.py` that uses
   `from monitoring_sdk import Pushgateway, Metric` and pushes metrics.
   Environment provided to the script: `PUSHGATEWAY_URL`, `JOB`, `SCRIPT`.
2. Add an entry to `monitoring_jobs` (name/script/job/schedule/description).
3. Merge to `develop` (nonprod) or `main` (prod). CI creates the EventBridge rule
   and syncs the script to S3. No Lambda redeploy required.

## Heartbeat & alarms

Every run (success or failure) pushes `monitoring_run_status{script,job,status}`
(1 = ok, 0 = failed) and `monitoring_run_timestamp_seconds`. Build a Grafana panel
that alerts when `monitoring_run_status == 0` or the timestamp is stale. Three
CloudWatch alarms (`errors`, `throttles`, `no-invocations`) back this up.

## Grafana-side requirement (outside this module)

For metrics to appear, the Prometheus config (stored in its S3 bucket in the
grafana-stack-aws deployment) must:

1. Have a scrape job targeting the Pushgateway (`pushgateway.<namespace>:9091`), and
2. Set `honor_labels: true` on that job, otherwise your per-monitor `job` labels
   are overwritten by the pushgateway scrape job name.

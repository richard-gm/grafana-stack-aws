include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/monitoring"
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "security" {
  config_path = "../security"
}

dependency "ecs" {
  config_path = "../ecs"
}

inputs = {
  project_name                  = include.root.locals.project_name
  env_subfix                    = include.root.locals.environment
  region                        = include.root.locals.region
  aws_account_id                = include.root.locals.account_id
  vpc_id                        = dependency.vpc.outputs.vpc_id
  private_subnet_ids            = dependency.vpc.outputs.private_subnet_ids
  pushgateway_security_group_id = dependency.security.outputs.ecs_security_group_id
  pushgateway_url               = "http://pushgateway.${dependency.ecs.outputs.service_discovery_namespace_name}:9091"
  tags_project                  = include.root.locals.tags

  # Modules run from .terragrunt-cache; point at the real repo tree.
  lambda_handler_path = "${get_parent_terragrunt_dir()}/src/lambda_handler.py"
  monitoring_sdk_dir  = "${get_parent_terragrunt_dir()}/src/monitoring_sdk"

  monitoring_jobs = [
    {
      name        = "rds-snapshots"
      script      = "check_rds_snapshots"
      job         = "rds-snapshots"
      schedule    = "cron(0 6 * * ? *)"
      description = "Report age of latest automated RDS snapshots"
    },
    {
      name        = "s3-lifecycle"
      script      = "check_s3_lifecycle"
      job         = "s3-lifecycle"
      schedule    = "cron(30 6 * * ? *)"
      description = "Flag S3 buckets missing a lifecycle configuration"
    },
    {
      name        = "github-status"
      script      = "check_github_status"
      job         = "github-status"
      schedule    = "cron(0 * * * ? *)"
      description = "Monitor GitHub status page + API reachability"
    },
  ]
}
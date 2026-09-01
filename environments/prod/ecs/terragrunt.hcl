include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/ecs"
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "security" {
  config_path = "../security"
}

dependency "ecr" {
  config_path = "../ecr-containers"
}

inputs = {
  project_name         = include.root.locals.project_name
  env_subfix           = include.root.locals.environment
  region               = include.root.locals.region
  aws_account_id       = include.root.locals.account_id
  vpc_id               = dependency.vpc.outputs.vpc_id
  private_subnet_ids   = dependency.vpc.outputs.private_subnet_ids
  public_subnets       = dependency.vpc.outputs.public_subnet_ids
  private_subnets      = dependency.vpc.outputs.private_subnet_ids
  ecs_sg_id            = dependency.security.outputs.ecs_security_group_id
  prometheus_efs_sg_id = dependency.security.outputs.efs_prometheus_security_group_id
  alb_sg_id            = dependency.security.outputs.alb_security_group_id
  tags_project         = include.root.locals.tags
  loki_repo_url        = dependency.ecr.outputs.loki_repo_url
  mimir_repo_url       = dependency.ecr.outputs.mimir_repo_url
  tempo_repo_url       = dependency.ecr.outputs.tempo_repo_url
  otel_repo_url        = dependency.ecr.outputs.otel_repo_url
}
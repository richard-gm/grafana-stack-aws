provider "aws" {
  region = var.region
}

module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  env_subfix   = var.env_subfix
  region       = var.region
  tags_project = var.tags_project
}

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  env_subfix   = var.env_subfix
  region       = var.region
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr
  tags_project = var.tags_project
}

module "ecr_containers" {
  source = "../../modules/ecr-containers"

  project_name = var.project_name
  env_subfix   = var.env_subfix
  region       = var.region
  tags_project = var.tags_project
}

module "ecs" {
  source = "../../modules/ecs"

  project_name           = var.project_name
  env_subfix             = var.env_subfix
  region                 = var.region
  aws_account_id         = var.aws_account_id
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  public_subnets         = module.vpc.public_subnet_ids
  private_subnets        = module.vpc.private_subnet_ids
  ecs_sg_id              = module.security.ecs_security_group_id
  prometheus_efs_sg_id   = module.security.efs_prometheus_security_group_id
  alb_sg_id              = module.security.alb_security_group_id
  tags_project           = var.tags_project
  loki_repo_url          = module.ecr_containers.loki_repo_url
  mimir_repo_url         = module.ecr_containers.mimir_repo_url
  tempo_repo_url         = module.ecr_containers.tempo_repo_url
  otel_repo_url          = module.ecr_containers.otel_repo_url
}

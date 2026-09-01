include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/security"
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  project_name = include.root.locals.project_name
  env_subfix   = include.root.locals.environment
  region       = include.root.locals.region
  vpc_id       = dependency.vpc.outputs.vpc_id
  vpc_cidr     = dependency.vpc.outputs.vpc_cidr
  tags_project = include.root.locals.tags
}
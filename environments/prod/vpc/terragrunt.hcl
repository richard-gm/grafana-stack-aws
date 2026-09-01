include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/vpc"
}

inputs = {
  project_name = include.root.locals.project_name
  env_subfix   = include.root.locals.environment
  region       = include.root.locals.region
  tags_project = include.root.locals.tags
}
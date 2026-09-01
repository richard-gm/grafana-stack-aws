include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/oidc"
}

inputs = {
  project_name = include.root.locals.project_name
  env_subfix   = include.root.locals.environment
  github_org   = include.root.locals.github_org
  github_repo  = include.root.locals.github_repo
  tags_project = include.root.locals.tags
}
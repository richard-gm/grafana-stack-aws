# Shared root config; every unit includes it with
# `find_in_parent_folders("root.hcl")`.

locals {
  pr = path_relative_to_include()

  # Environment from the unit path, e.g. environments/nonprod/vpc -> nonprod.
  # Falls back to TG_ENV (set by CI).
  environment = can(regex("^[^/]+/([^/]+)/[^/]+/?$", local.pr)) ? regex("^[^/]+/([^/]+)/[^/]+/?$", local.pr)[0] : get_env("TG_ENV", "nonprod")

  common = read_terragrunt_config("${get_parent_terragrunt_dir()}/_env/common.hcl").locals
  env    = read_terragrunt_config("${get_parent_terragrunt_dir()}/_env/${local.environment}.hcl").locals

  project_name = local.common.project_name
  region       = local.common.region
  account_id   = local.env.account_id
  github_org   = local.common.github_org
  github_repo  = local.common.github_repo

  tags = merge(local.common.tags, local.env.tags)
}

# Provider block shared by every unit; region/tags come from the env files.
generate "provider" {
  path      = "provider.generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOT
    provider "aws" {
      region = "${local.region}"
      default_tags {
        tags = ${jsonencode(local.tags)}
      }
    }
  EOT
}

# One S3 state per unit, keyed by unit path.
#
# The bucket is bootstrapped once per account with `terragrunt backend
# bootstrap` (enables versioning + SSE). No lock table; if concurrent writes
# are a concern, enable Terraform's S3-native lock via `use_lockfile`.
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.generated.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket  = "grafana-stack-terraform-state-${local.environment}"
    key     = "${local.pr}/terraform.tfstate"
    region  = local.region
    encrypt = true
  }
}
# Settings shared by all environments.
locals {
  project_name = "grafana-stack"
  region       = "us-east-1"

  # Used by the OIDC module to scope the GitHub Actions role to this repo.
  github_org  = ""
  github_repo = ""

  tags = {
    Project   = "grafana-stack"
    ManagedBy = "terragrunt"
  }
}
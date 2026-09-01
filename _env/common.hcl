# Settings shared by all environments.
locals {
  project_name = "grafana-stack"
  region       = "us-east-1"

  # OIDC scope for the GitHub Actions role. Injected by CI from repo
  # variables; export locally (e.g. `export GITHUB_ORG=...`).
  github_org  = get_env("GITHUB_ORG", "")
  github_repo = get_env("GITHUB_REPO", "")

  tags = {
    Project   = "grafana-stack"
    ManagedBy = "terragrunt"
  }
}
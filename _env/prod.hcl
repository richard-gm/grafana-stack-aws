# Prod-specific settings.
locals {
  # Injected by CI from the AWS_ACCOUNT_ID_PROD repo variable; export
  # locally to run against the prod account.
  account_id = get_env("AWS_ACCOUNT_ID_PROD", "")

  tags = {
    Environment = "prod"
  }
}
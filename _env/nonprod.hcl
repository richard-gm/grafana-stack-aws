# Nonprod-specific settings.
locals {
  # Injected by CI from the AWS_ACCOUNT_ID_NONPROD repo variable; export
  # locally to run against the nonprod account.
  account_id = get_env("AWS_ACCOUNT_ID_NONPROD", "")

  tags = {
    Environment = "nonprod"
  }
}
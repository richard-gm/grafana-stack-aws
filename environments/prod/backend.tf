terraform {
  backend "s3" {
    bucket         = "grafana-stack-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    versioning     = true
  }
}

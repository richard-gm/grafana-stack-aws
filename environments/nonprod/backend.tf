terraform {
  backend "s3" {
    bucket     = "grafana-stack-terraform-state"
    key        = "nonprod/terraform.tfstate"
    region     = "us-east-1"
    encrypt    = true
    versioning = true
  }
}

resource "aws_service_discovery_private_dns_namespace" "monitoring" {
  name        = "monitoring.dns"
  description = "Service Connect namespace for monitoring stack"
  vpc         = var.vpc_id
}

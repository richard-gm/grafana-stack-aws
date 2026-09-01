# ------------------------------------------------------------------------------
# ACM (TLS certificate) - DISABLED BY DEFAULT
# ------------------------------------------------------------------------------
# Grafana is fronted by Duo SSO and only reachable over internal links, so no
# public cert is needed in non-prod. Enable for a public-facing ALB:
#   1. Uncomment the variables and resources below.
#   2. Uncomment the `certificate_arn` output in outputs.tf.
#   3. Uncomment `acm:*` / `route53:*` in modules/oidc/main.tf.
#   4. Uncomment the 443 ingress in the ALB security group (main.tf).
#   5. Add an HTTPS listener in modules/ecs/alb.tf referencing
#      `module.security.certificate_arn`.
# ------------------------------------------------------------------------------
#
# variable "certificate_arn" {
#   description = "ARN of the ACM certificate for SSL/TLS (leave empty to create new)"
#   type        = string
#   default     = ""
# }
#
# variable "domain_name" {
#   description = "Domain name for the ACM certificate"
#   type        = string
#   default     = ""
# }
#
# variable "route53_zone_id" {
#   description = "Route53 hosted zone ID for ACM certificate validation"
#   type        = string
#   default     = ""
# }
#
# resource "aws_acm_certificate" "main" {
#   count             = var.certificate_arn == "" && var.domain_name != "" ? 1 : 0
#   domain_name       = var.domain_name
#   validation_method = "DNS"
#
#   tags = merge(
#     var.tags_project,
#     {
#       Name = "${var.project_name}-cert-${var.env_subfix}"
#     }
#   )
#
#   lifecycle {
#     create_before_destroy = true
#   }
# }
#
# resource "aws_route53_record" "cert_validation" {
#   count   = var.certificate_arn == "" && var.domain_name != "" ? 1 : 0
#   name    = tolist(aws_acm_certificate.main[0].domain_validation_options)[0].resource_record_name
#   type    = tolist(aws_acm_certificate.main[0].domain_validation_options)[0].resource_record_type
#   zone_id = var.route53_zone_id
#   records = [tolist(aws_acm_certificate.main[0].domain_validation_options)[0].resource_record_value]
#   ttl     = 60
# }
#
# resource "aws_acm_certificate_validation" "main" {
#   count                   = var.certificate_arn == "" && var.domain_name != "" ? 1 : 0
#   certificate_arn         = aws_acm_certificate.main[0].arn
#   validation_record_fqdns = [aws_route53_record.cert_validation[0].fqdn]
# }

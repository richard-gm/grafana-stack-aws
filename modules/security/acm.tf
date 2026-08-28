# ------------------------------------------------------------------------------
# ACM (TLS certificate) - DISABLED BY DEFAULT
# ------------------------------------------------------------------------------
# This module creates an ACM certificate used to terminate TLS on the ALB so
# Grafana can be served over HTTPS. It is intentionally commented out because:
#
#   * In non-prod / internal-only setups Grafana is fronted by Duo SSO and the
#     data is only visible to a restricted set of users, so a public cert is not
#     required.
#   * All traffic between AWS services (Lambda monitoring scripts, ECS, S3, etc.)
#     is already encrypted in transit by AWS's network fabric.
#
# ENABLE IN PROD IF:
#   * The ALB is internet-facing (`internal = false`) and you expose Grafana to
#     end users over the public internet.
#   OR
#   * You import your own certificate into AWS (e.g. via aws_acm_certificate
#     import / ACM console) and pass its ARN via the `certificate_arn` variable,
#     then attach it to an `aws_lb_listener` on port 443 in modules/ecs/alb.tf.
#
# To enable:
#   1. Uncomment the variable declarations below (or add them to variables.tf).
#   2. Uncomment the resources below.
#   3. Uncomment the `certificate_arn` output in outputs.tf.
#   4. Uncomment `acm:*` / `route53:*` in modules/oidc/main.tf.
#   5. Uncomment the 443 ingress in the ALB security group (main.tf).
#   6. Add an HTTPS listener in modules/ecs/alb.tf referencing
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

output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS"
  value       = aws_security_group.ecs.id
}

output "efs_prometheus_security_group_id" {
  description = "Security group ID for Prometheus EFS"
  value       = aws_security_group.efs_prometheus.id
}

output "efs_grafana_security_group_id" {
  description = "Security group ID for Grafana EFS"
  value       = aws_security_group.efs_grafana.id
}

output "nlb_security_group_id" {
  description = "Security group ID for NLB"
  value       = aws_security_group.nlb.id
}

# output "certificate_arn" {
#   description = "ARN of the ACM certificate (enable ACM in acm.tf)"
#   value       = var.certificate_arn != "" ? var.certificate_arn : (length(aws_acm_certificate.main) > 0 ? aws_acm_certificate.main[0].arn : "")
# }

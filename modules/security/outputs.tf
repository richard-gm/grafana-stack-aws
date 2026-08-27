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

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.main.arn
}

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.main.key_id
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = var.certificate_arn != "" ? var.certificate_arn : (length(aws_acm_certificate.main) > 0 ? aws_acm_certificate.main[0].arn : "")
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "grafana_alb_dns" {
  description = "DNS name of the Grafana ALB"
  value       = aws_lb.grafana.dns_name
}

output "grafana_alb_arn" {
  description = "ARN of the Grafana ALB"
  value       = aws_lb.grafana.arn
}

output "grafana_target_group_arn" {
  description = "ARN of the Grafana target group"
  value       = aws_lb_target_group.grafana.arn
}

output "service_discovery_namespace_arn" {
  description = "ARN of the Service Connect namespace"
  value       = aws_service_discovery_private_dns_namespace.monitoring.arn
}

output "service_discovery_namespace_name" {
  description = "Name of the Service Connect namespace"
  value       = aws_service_discovery_private_dns_namespace.monitoring.name
}

output "prometheus_service_name" {
  description = "Name of the Prometheus ECS service"
  value       = aws_ecs_service.prometheus.name
}

output "grafana_service_name" {
  description = "Name of the Grafana ECS service"
  value       = aws_ecs_service.grafana.name
}

output "pushgateway_service_name" {
  description = "Name of the Pushgateway ECS service"
  value       = aws_ecs_service.pushgateway.name
}

output "loki_service_name" {
  description = "Name of the Loki ECS service"
  value       = aws_ecs_service.loki.name
}

output "mimir_service_name" {
  description = "Name of the Mimir ECS service"
  value       = aws_ecs_service.mimir.name
}

output "tempo_service_name" {
  description = "Name of the Tempo ECS service"
  value       = aws_ecs_service.tempo.name
}

output "otel_service_name" {
  description = "Name of the OTel Collector ECS service"
  value       = aws_ecs_service.otel.name
}

output "prometheus_ecr_repo_url" {
  description = "ECR repository URL for Prometheus"
  value       = aws_ecr_repository.prometheus.repository_url
}

output "grafana_ecr_repo_url" {
  description = "ECR repository URL for Grafana"
  value       = aws_ecr_repository.grafana.repository_url
}

output "pushgateway_ecr_repo_url" {
  description = "ECR repository URL for Pushgateway"
  value       = aws_ecr_repository.pushgateway.repository_url
}

output "prometheus_efs_id" {
  description = "ID of the Prometheus EFS"
  value       = aws_efs_file_system.prometheus.id
}

output "grafana_efs_id" {
  description = "ID of the Grafana EFS"
  value       = aws_efs_file_system.grafana.id
}

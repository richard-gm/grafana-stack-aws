output "ecs_task_execution_role_arn" {
    value = aws_iam_role.ecs_task_execution_role.arn
}

output "efs_file_system_id" {
    value = aws_efs_file_system.prometheus.id
}

output "efs_file_system_arn" {
    value = aws_efs_file_system.prometheus.arn
}

output "grafana_alb" {
    value = aws_lb.grafana_alb.dns_name
}

output "pushgateway_private_dns_name" {
    value = aws_service_discovery_private_dns_namespace.monitoring_dns.name
}

output "prometheus_config_bucket" {
    description = "The S3 bucket name for Prometheus configuration files"
    value       = aws_s3_bucket.prometheus_config.bucket
}

# ECS Cluster Output
output "cluster_name" {
    description = "Name of the ECS cluster"
    value       = aws_ecs_cluster.ecs_prometheus-grafana-cluster.name
}

# ECS Service Names for Monitoring
output "prometheus_service_name" {
    description = "Name of the Prometheus ECS service"
    value       = aws_ecs_service.prometheus.name
}

output "grafana_service_name" {
    description = "Name of the Grafana ECS service"
    value       = aws_ecs_service.grafana_service.name
}

output "pushgateway_service_name" {
    description = "Name of the Pushgateway ECS service"
    value       = aws_ecs_service.prometheus_pushgateway_service.name
}

# Additional useful outputs for monitoring
output "cluster_arn" {
    description = "ARN of the ECS cluster"
    value       = aws_ecs_cluster.ecs_prometheus-grafana-cluster.arn
}

output "prometheus_service_arn" {
    description = "ARN of the Prometheus ECS service"
    value       = aws_ecs_service.prometheus.id
}

output "grafana_service_arn" {
    description = "ARN of the Grafana ECS service"
    value       = aws_ecs_service.grafana_service.id
}

output "pushgateway_service_arn" {
    description = "ARN of the Pushgateway ECS service"
    value       = aws_ecs_service.prometheus_pushgateway_service.id
}

output "loki_repo_url" {
  description = "ECR repository URL for Loki"
  value       = aws_ecr_repository.loki_repo.repository_url
}

output "grafana_repo_url" {
  description = "ECR repository URL for Grafana"
  value       = aws_ecr_repository.grafana_repo.repository_url
}

output "mimir_repo_url" {
  description = "ECR repository URL for Mimir"
  value       = aws_ecr_repository.mimir_repo.repository_url
}

output "tempo_repo_url" {
  description = "ECR repository URL for Tempo"
  value       = aws_ecr_repository.tempo_repo.repository_url
}

output "otel_repo_url" {
  description = "ECR repository URL for OTel Collector"
  value       = aws_ecr_repository.otel_repo.repository_url
}

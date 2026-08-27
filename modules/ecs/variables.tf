variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "env_subfix" {
  description = "Environment suffix"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "Security Group ID for ECS"
  type        = string
}

variable "prometheus_efs_sg_id" {
  description = "Security Group ID for Prometheus EFS"
  type        = string
}

variable "alb_sg_id" {
  description = "Security Group ID for ALB"
  type        = string
}

variable "tags_project" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

variable "loki_repo_url" {
  description = "ECR repository URL for Loki"
  type        = string
}

variable "mimir_repo_url" {
  description = "ECR repository URL for Mimir"
  type        = string
}

variable "tempo_repo_url" {
  description = "ECR repository URL for Tempo"
  type        = string
}

variable "otel_repo_url" {
  description = "ECR repository URL for OTel Collector"
  type        = string
}

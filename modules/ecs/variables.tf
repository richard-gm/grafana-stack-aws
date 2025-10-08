variable "project_name" {
    description = "The name of the project"
    type        = string
}

variable "tags_project" {
    description = "Tags to apply to all resources."
    type        = map(string)
}

variable "env_subfix" {
    description = "env_subfix ID"
    type        = string
}

variable "private_subnet_ids" {
    description = "Subnet IDs"
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

variable "public_subnets" {
    description = "List of public subnet IDs"
    type        = list(string)
}

variable "private_subnets" {
    description = "List of private subnet IDs"
    type        = list(string)
}

variable "alb_sg_id" {
    description = "The name of the VPC."
    type        = string
}

variable "ontrack_api_client_id" {
    description = "API Client ID for the project"
    type        = string
}

variable "ontrack_api_client_secret" {
    description = "API Client Secret for the project"
    type        = string
}

variable "prometheus_nlb_dns_name" {
    description = "The value of the NLB URL for Prometheus"
    type        = string
}

variable "prometheus_pushgateway_tg" {
    description = "The value of the Prometheus Pushgateway Target Group"
    type        = string
}

variable "prometheus_main_tg" {
    description = "The value of the Prometheus Main Target Group"
    type        = string
}

variable "pushgateway_private_dns_name" {
    description = "The value of the Pushgateway DNS name"
    type        = string
}

variable "prometheus_private_dns_name" {
    description = "The value of the Prometheus DNS name"
    type        = string
}

# Third-party access configuration variables
variable "enable_third_party_access" {
    description = "Enable third-party access to AMP workspace"
    type        = bool
    default     = true
}

# Timestream adapter de-duplication / rate limiting controls
variable "ts_dedup_enabled" {
  description = "Enable de-duplication and rate-limiting in the Timestream adapter"
  type        = bool
  default     = true
}

variable "ts_min_write_interval_seconds" {
  description = "Minimum seconds between writes for the same time series (refresh cadence)"
  type        = number
  default     = 3600 # 1 hour, to align with hourly/6h/daily jobs and reduce minute-level duplicates
}

variable "ts_value_change_epsilon" {
  description = "Absolute value change required to trigger a write within the interval (DOUBLE metrics)"
  type        = number
  default     = 0.0
}

variable "ts_value_change_rel_epsilon" {
  description = "Relative value change fraction required to trigger a write within the interval"
  type        = number
  default     = 0.0
}

variable "ts_dedup_cache_max_size" {
  description = "Max unique series entries tracked for de-dup cache (LRU-like trimming)"
  type        = number
  default     = 200000
}

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

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for SSL/TLS (leave empty to create new)"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for the ACM certificate"
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for ACM certificate validation"
  type        = string
  default     = ""
}

variable "tags_project" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

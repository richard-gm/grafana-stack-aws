variable "project_name" {
  type        = string
  description = "Prefix used for all resource names"
}

variable "env_subfix" {
  type        = string
  description = "Environment suffix, e.g. nonprod or prod"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "aws_account_id" {
  type        = string
  description = "AWS account ID where resources are created"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID from the grafana-stack-aws deployment"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs (from grafana-stack-aws VPC module output)"
}

variable "pushgateway_security_group_id" {
  type        = string
  description = "Security group protecting the Pushgateway (the grafana ECS SG). The module adds an ingress rule allowing this Lambda's SG on :9091."
}

variable "lambda_policy_json" {
  type        = string
  description = "IAM policy JSON attached to the Lambda role for the AWS APIs your monitors read. Default is a curated read-only (Describe/List/Get) set; override per environment."
  default     = <<-EOT
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "rds:Describe*", "rds:List*",
            "s3:ListAllMyBuckets", "s3:ListBucket", "s3:GetBucket*", "s3:GetLifecycleConfiguration",
            "ec2:Describe*",
            "cloudwatch:GetMetricData", "cloudwatch:ListMetrics", "cloudwatch:Describe*",
            "elasticloadbalancing:Describe*",
            "lambda:List*", "lambda:Get*",
            "dynamodb:DescribeTable", "dynamodb:ListTables", "dynamodb:Scan", "dynamodb:GetItem",
            "ecs:Describe*", "ecs:List*",
            "sqs:GetQueueAttributes", "sqs:ListQueues", "sqs:ReceiveMessage",
            "apigateway:GET",
            "cloudfront:Get*", "cloudfront:List*"
          ],
          "Resource": "*"
        }
      ]
    }
  EOT
}

variable "alarm_actions" {
  type        = list(string)
  default     = []
  description = "ARNs (e.g. SNS topics) to notify when monitoring alarms fire. Empty = alarm state only."
}

variable "missed_run_period" {
  type        = number
  default     = 86400
  description = "Seconds over which to require at least one Lambda invocation (catches dead EventBridge schedules)."
}

variable "pushgateway_url" {
  type        = string
  default     = "http://pushgateway.monitoring:9091"
  description = "URL of the Prometheus Pushgateway (Service Connect DNS from grafana-stack-aws)."
}

variable "lambda_runtime" {
  type    = string
  default = "python3.12"
}

variable "tags_project" {
  type        = map(string)
  default     = {}
  description = "Common tags merged into all resources"
}

variable "monitoring_jobs" {
  type = list(object({
    name        = string
    script      = string
    job         = string
    schedule    = string
    description = string
  }))
  default     = []
  description = "List of monitors. Each becomes an EventBridge schedule rule invoking the Lambda."
}

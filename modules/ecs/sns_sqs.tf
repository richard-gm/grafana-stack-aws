# SNS Topic for configuration updates
resource "aws_sns_topic" "config_updates" {
  name = "${var.project_name}-config-updates-${var.env_subfix}"
  
  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-config-updates-${var.env_subfix}"
    }
  )
}

# SQS Queue for Prometheus config updates
resource "aws_sqs_queue" "prometheus_config_updates" {
  name                      = "${var.project_name}-prometheus-config-updates-${var.env_subfix}"
  message_retention_seconds = 1209600  # 14 days
  visibility_timeout_seconds = 300

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-prometheus-config-updates-${var.env_subfix}"
    }
  )
}

# SNS subscription to SQS
resource "aws_sns_topic_subscription" "prometheus_config_updates" {
  topic_arn = aws_sns_topic.config_updates.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.prometheus_config_updates.arn
}

# SQS Queue Policy to allow SNS to send messages
resource "aws_sqs_queue_policy" "prometheus_config_updates" {
  queue_url = aws_sqs_queue.prometheus_config_updates.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.prometheus_config_updates.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.config_updates.arn
          }
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
            type        = "Service"
            identifiers = ["ecs-tasks.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "ecs_task_role" {
    name               = "${var.project_name}-EcsTaskRole"
    assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
}

# IMPORTANT - Allows ECS tasks to use SSM - Session Manager into the container
resource "aws_iam_policy" "ecs_exec_policy" {
    name        = "${var.project_name}-ecsExecPolicy"
    description = "Policy to allow ECS Exec"
    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "ssmmessages:CreateControlChannel",
                    "ssmmessages:CreateDataChannel",
                    "ssmmessages:OpenControlChannel",
                    "ssmmessages:OpenDataChannel"
                ],
                Resource = "*"
            }
        ]
    })
}

# This resource attaches the ECS Exec policy to the ECS Task Role
resource "aws_iam_role_policy_attachment" "ecs_exec_policy_attachment_task_role" {
    role       = aws_iam_role.ecs_task_role.name
    policy_arn = aws_iam_policy.ecs_exec_policy.arn
}

# This resource attaches the AmazonECSTaskExecutionRolePolicy policy to the ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
    name               = "${var.project_name}-ecsTaskExecutionRole"
    assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
}

# This resource attaches the ECS Exec policy to the ECS Task Execution Role
resource "aws_iam_role_policy_attachment" "ecs_exec_policy_attachment_execution_role" {
    role       = aws_iam_role.ecs_task_execution_role.name
    policy_arn = aws_iam_policy.ecs_exec_policy.arn
}



# This policy allows ECS tasks to access S3 for Prometheus configuration
resource "aws_iam_role_policy" "ecs_task_s3_access" {
    name   = "EcsTaskS3Access"
    role   = aws_iam_role.ecs_task_role.id # IMPORTANT, policy roles must be attached to the task role to run code inside the container. S3, DynamoDB, etc.
    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "s3:GetObject",
                    "s3:ListBucket"
                ],
                Resource = [
                    aws_s3_bucket.prometheus_config.arn,
                    "${aws_s3_bucket.prometheus_config.arn}/*"
                ]
            }
        ]
    })
}



# this policy allows ECS tasks to write logs to CloudWatch
resource "aws_iam_policy" "ecs_task_logging_policy" {
    name        = "${var.project_name}-${var.env_subfix}-logging-policy"
    description = "Policy for ECS Task to write logs to CloudWatch"

    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ],
                Resource = "arn:aws:logs:${var.region}:${var.aws_account_id}:log-group:${aws_cloudwatch_log_group.ecs_task_log_group.name}:*"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "ecs_task_logging_policy_attachment" {
    role       = aws_iam_role.ecs_task_execution_role.name
    policy_arn = aws_iam_policy.ecs_task_logging_policy.arn
}



# ECS task execution role is responsible for authenticating with ECR to pull images
# ECS execution role Grants ECS permission to perform actions on your behalf needed to launch and manage the container/task.
# ECR, Secret manager or SSM parameter store resources fall under this role.
resource "aws_iam_policy" "ecs_task_execution_policy" {
    name        = "${var.project_name}-ecs-task-execution-policy"
    description = "Policy for ECS Task Execution Role"
    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "ecr:GetAuthorizationToken",
                    "ecr:BatchCheckLayerAvailability",
                    "ecr:GetDownloadUrlForLayer",
                    "ecr:BatchGetImage"
                ],
                Resource = "*"
            },
            {
                Effect = "Allow",
                Action = [
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ],
                Resource = "*"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment" {
    role       = aws_iam_role.ecs_task_execution_role.name
    policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
}


####### This policy allows ECS tasks to access EFS and S3 for Prometheus configuration ######

resource "aws_iam_policy" "ecs_task_policy" {
    name        = "${var.project_name}-ecs-task-policy"
    description = "Policy to allow ECS tasks to access EFS and S3"

    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "elasticfilesystem:ClientMount",
                    "elasticfilesystem:ClientWrite",
                    "elasticfilesystem:ClientRootAccess"
                ],
                Resource = "arn:aws:elasticfilesystem:${var.region}:${var.aws_account_id}:file-system/${aws_efs_file_system.prometheus.id}"
            },
            {
                Effect = "Allow",
                Action = [
                    "s3:GetObject",
                    "s3:ListBucket"
                ],
                Resource = [
                    "arn:aws:s3:::${aws_s3_bucket.prometheus_config.bucket}",
                    "arn:aws:s3:::${aws_s3_bucket.prometheus_config.bucket}/*"
                ]
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy_attachment" {
    role       = aws_iam_role.ecs_task_role.name  # Changed from ecs_task_execution_role to ecs_task_role
    policy_arn = aws_iam_policy.ecs_task_policy.arn
}


# Create IAM policy for AWS Secret manager CreateSecret PutSecretValue and GetSecretValue. Also its used to for pull registry auth from Amazon ECR, else, the ECS task will not be able to pull the image from ECR if the image is private.
resource "aws_iam_policy" "aws_secret_manager_policy" {
    name        = "${var.project_name}-aws-secret-manager-policy"
    description = "Policy to allow ECS tasks to access AWS Secrets Manager"

    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "secretsmanager:CreateSecret",
                    "secretsmanager:PutSecretValue",
                    "secretsmanager:GetSecretValue"
                ],
                Resource = "*"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "aws_secret_manager_policy_attachment" {
    role       = aws_iam_role.ecs_task_execution_role.name
    policy_arn = aws_iam_policy.aws_secret_manager_policy.arn
}


# IMPORTANT For ECS scheduled tasks

resource "aws_iam_role" "eventbridge_ecs_task_role" {
    name = "eventbridge-ecs-task-role-${var.env_subfix}"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = {
                Service = "events.amazonaws.com"
            }
            Action = "sts:AssumeRole"
        }]
    })

    tags = merge(
        var.tags_project,
        {
            Name = "eventbridge-ecs-task-role-${var.env_subfix}"
        }
    )
}

resource "aws_iam_role_policy" "eventbridge_ecs_task_policy" {
    name = "eventbridge-ecs-task-policy-${var.env_subfix}"
    role = aws_iam_role.eventbridge_ecs_task_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "ecs:RunTask",
                    "ecs:StopTask",
                    "ecs:DescribeTasks"
                ]
                Resource = "*"
            },
            {
                Effect = "Allow"
                Action = [
                    "iam:PassRole"
                ]
                Resource = [
                    aws_iam_role.ecs_task_execution_role.arn,
                    aws_iam_role.ecs_task_role.arn
                ]
            }
        ]
    })
}

# S3 and SQS permissions for Prometheus config management
resource "aws_iam_policy" "prometheus_s3_sqs_policy" {
    name        = "${var.project_name}-prometheus-s3-sqs-policy-${var.env_subfix}"
    description = "Policy to allow Prometheus to access S3 config bucket and SQS queue"
    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "s3:GetObject",
                    "s3:ListBucket",
                    "s3:HeadObject"
                ],
                Resource = [
                    aws_s3_bucket.prometheus_config.arn,
                    "${aws_s3_bucket.prometheus_config.arn}/*"
                ]
            },
            {
                Effect = "Allow",
                Action = [
                    "sqs:ReceiveMessage",
                    "sqs:DeleteMessage",
                    "sqs:GetQueueAttributes"
                ],
                Resource = aws_sqs_queue.prometheus_config_updates.arn
            }
        ]
    })

    tags = merge(
        var.tags_project,
        {
            Name = "${var.project_name}-prometheus-s3-sqs-policy-${var.env_subfix}"
        }
    )
}

# Attach S3/SQS policy to the existing ECS Task Role
resource "aws_iam_role_policy_attachment" "prometheus_s3_sqs_policy_attachment" {
    role       = aws_iam_role.ecs_task_role.name
    policy_arn = aws_iam_policy.prometheus_s3_sqs_policy.arn
}

# SSM Parameter Store access policy for ECS Task Execution Role
# This is needed for the "secrets" section in ECS task definitions
resource "aws_iam_policy" "ecs_task_execution_ssm_policy" {
    name        = "${var.project_name}-ecs-task-execution-ssm-policy"
    description = "Policy for ECS Task Execution Role to access SSM Parameter Store secrets"

    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "ssm:GetParameters",
                    "ssm:GetParameter"
                ],
                Resource = [
                    "arn:aws:ssm:${var.region}:${var.aws_account_id}:parameter/${var.project_name}/amp/grafana-service/*",
                    "arn:aws:ssm:${var.region}:${var.aws_account_id}:parameter/${var.project_name}/amp/dsi-team/*"
                ]
            }
        ]
    })

    tags = merge(
        var.tags_project,
        {
            Name = "${var.project_name}-ecs-task-execution-ssm-policy"
        }
    )
}

# Attach SSM policy to ECS Task Execution Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_ssm_policy_attachment" {
    role       = aws_iam_role.ecs_task_execution_role.name
    policy_arn = aws_iam_policy.ecs_task_execution_ssm_policy.arn
}

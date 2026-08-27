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
  name               = "${var.project_name}-ecs-task-role-${var.env_subfix}"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-ecs-task-role-${var.env_subfix}"
    }
  )
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project_name}-ecs-task-execution-role-${var.env_subfix}"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-ecs-task-execution-role-${var.env_subfix}"
    }
  )
}

resource "aws_iam_policy" "ecs_exec_policy" {
  name        = "${var.project_name}-ecs-exec-policy-${var.env_subfix}"
  description = "Policy to allow ECS Exec"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_policy_attachment_task_role" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_exec_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_exec_policy_attachment_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_exec_policy.arn
}

resource "aws_iam_policy" "ecs_task_execution_policy" {
  name        = "${var.project_name}-ecs-task-execution-policy-${var.env_subfix}"
  description = "Policy for ECS Task Execution Role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
}

resource "aws_iam_policy" "ecs_task_logging_policy" {
  name        = "${var.project_name}-ecs-task-logging-policy-${var.env_subfix}"
  description = "Policy for ECS Task to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${var.aws_account_id}:log-group:/ecs/*-${var.env_subfix}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_logging_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_logging_policy.arn
}

resource "aws_iam_policy" "ecs_task_s3_access" {
  name        = "${var.project_name}-ecs-task-s3-access-${var.env_subfix}"
  description = "Policy to allow ECS tasks to access S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:HeadObject"
        ]
        Resource = [
          aws_s3_bucket.prometheus_config.arn,
          "${aws_s3_bucket.prometheus_config.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_s3_access_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_s3_access.arn
}

resource "aws_iam_policy" "ecs_task_efs_access" {
  name        = "${var.project_name}-ecs-task-efs-access-${var.env_subfix}"
  description = "Policy to allow ECS tasks to access EFS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_efs_access_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_efs_access.arn
}



resource "aws_iam_policy" "aws_secret_manager_policy" {
  name        = "${var.project_name}-aws-secret-manager-policy-${var.env_subfix}"
  description = "Policy to allow ECS tasks to access AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_secret_manager_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.aws_secret_manager_policy.arn
}

resource "aws_iam_role" "eventbridge_ecs_task_role" {
  name = "${var.project_name}-eventbridge-ecs-task-role-${var.env_subfix}"

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
      Name = "${var.project_name}-eventbridge-ecs-task-role-${var.env_subfix}"
    }
  )
}

resource "aws_iam_role_policy" "eventbridge_ecs_task_policy" {
  name = "${var.project_name}-eventbridge-ecs-task-policy-${var.env_subfix}"
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

resource "aws_iam_policy" "ecs_task_execution_ssm_policy" {
  name        = "${var.project_name}-ecs-task-execution-ssm-policy-${var.env_subfix}"
  description = "Policy for ECS Task Execution Role to access SSM Parameter Store secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = [
          "arn:aws:ssm:${var.region}:${var.aws_account_id}:parameter/${var.project_name}/*"
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

resource "aws_iam_role_policy_attachment" "ecs_task_execution_ssm_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_ssm_policy.arn
}

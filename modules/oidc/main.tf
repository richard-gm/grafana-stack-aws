data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-github-oidc-${var.env_subfix}"
    }
  )
}

resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-${var.env_subfix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-github-actions-${var.env_subfix}"
    }
  )
}

resource "aws_iam_role_policy" "github_actions_terraform" {
  name = "${var.project_name}-github-actions-terraform-${var.env_subfix}"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-terraform-state-${var.env_subfix}",
          "arn:aws:s3:::${var.project_name}-terraform-state-${var.env_subfix}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "ecs:*",
          "ecr:*",
          "efs:*",
          "elasticloadbalancing:*",
          "iam:*",
          "s3:*",
          "logs:*",
          "cloudwatch:*",
          "ssm:*",
          "secretsmanager:*",
          "sts:AssumeRole",
          "sts:GetCallerIdentity",
          "kms:*",
          "acm:*",
          "route53:*",
          "servicediscovery:*",
          "sns:*",
          "sqs:*"
        ]
        Resource = "*"
      }
    ]
  })
}

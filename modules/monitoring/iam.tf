resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-monitoring-lambda-${var.env_subfix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags_project, {
    Name = "${var.project_name}-monitoring-lambda-${var.env_subfix}"
  })
}

# VPC networking (ENI create/delete) for the Lambda
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "lambda_inline" {
  name = "${var.project_name}-monitoring-lambda-inline-${var.env_subfix}"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.scripts.arn,
          "${aws_s3_bucket.scripts.arn}/*"
        ]
      }
    ]
  })
}

# Read-only permissions for the AWS services the monitors inspect.
resource "aws_iam_role_policy" "lambda_monitoring_read" {
  name = "${var.project_name}-monitoring-read-${var.env_subfix}"
  role = aws_iam_role.lambda.id

  policy = var.lambda_policy_json
}

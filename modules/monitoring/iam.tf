# Execution role assumed by the monitoring Lambda. The trust policy allows
# the Lambda service to assume it; the actual permissions are attached below.
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

# The Lambda runs inside the VPC (private subnets), so it needs the AWS-
# managed policy that grants ENI create/delete and CloudWatch Logs permissions.
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

#  Minimal inline permissions the Lambda always needs:
#  - CloudWatch Logs so we can debug script output,
#  - read of the scripts bucket so it can download the script to execute.
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

# Read-only AWS API access for whatever the monitors inspect (RDS, S3,
# EC2, CloudWatch, etc.). Centralised here so individual scripts never need their
# own IAM. Override `lambda_policy_json` per environment if a monitor needs more.
resource "aws_iam_role_policy" "lambda_monitoring_read" {
  name = "${var.project_name}-monitoring-read-${var.env_subfix}"
  role = aws_iam_role.lambda.id

  policy = var.lambda_policy_json
}

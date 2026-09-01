# ------------------------------------------------------------------------------
# Scripts bucket
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "scripts" {
  bucket = "monitoring-scripts-${var.aws_account_id}-${var.env_subfix}"

  tags = merge(var.tags_project, {
    Name = "${var.project_name}-monitoring-scripts-${var.env_subfix}"
  })
}

resource "aws_s3_bucket_versioning" "scripts" {
  bucket = aws_s3_bucket.scripts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "scripts" {
  bucket = aws_s3_bucket.scripts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "scripts" {
  bucket                  = aws_s3_bucket.scripts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# Lambda layer - shared monitoring_sdk package
# ------------------------------------------------------------------------------
data "archive_file" "layer" {
  type = "zip"

  output_path = "${path.module}/_build/layer.zip"

  source {
    content  = file("${var.monitoring_sdk_dir}/__init__.py")
    filename = "python/lib/python3.12/site-packages/monitoring_sdk/__init__.py"
  }

  source {
    content  = file("${var.monitoring_sdk_dir}/pushgw.py")
    filename = "python/lib/python3.12/site-packages/monitoring_sdk/pushgw.py"
  }
}

resource "aws_lambda_layer_version" "sdk" {
  filename            = data.archive_file.layer.output_path
  source_code_hash    = data.archive_file.layer.output_base64sha256
  layer_name          = "${var.project_name}-monitoring-sdk-${var.env_subfix}"
  compatible_runtimes = [var.lambda_runtime]
  description         = "Shared monitoring SDK (Pushgateway client)"
}

# ------------------------------------------------------------------------------
# Lambda function - single dispatcher for all scheduled monitors
# ------------------------------------------------------------------------------
data "archive_file" "lambda" {
  type = "zip"

  output_path = "${path.module}/_build/lambda.zip"

  source {
    content  = file(var.lambda_handler_path)
    filename = "lambda_handler.py"
  }

  source {
    content  = file("${var.monitoring_sdk_dir}/__init__.py")
    filename = "monitoring_sdk/__init__.py"
  }

  source {
    content  = file("${var.monitoring_sdk_dir}/pushgw.py")
    filename = "monitoring_sdk/pushgw.py"
  }
}

# ------------------------------------------------------------------------------
# Networking - Lambda SG + ingress to the Pushgateway
# ------------------------------------------------------------------------------
resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-monitoring-lambda-sg-${var.env_subfix}"
  description = "SG for the monitoring Lambda; egress to AWS APIs and the Pushgateway"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags_project, {
    Name = "${var.project_name}-monitoring-lambda-sg-${var.env_subfix}"
  })
}

resource "aws_security_group_rule" "pushgateway_ingress" {
  type                     = "ingress"
  security_group_id        = var.pushgateway_security_group_id
  source_security_group_id = aws_security_group.lambda.id
  from_port                = 9091
  to_port                  = 9091
  protocol                 = "tcp"
  description              = "Allow monitoring Lambda to reach the Pushgateway"
}

resource "aws_lambda_function" "monitoring" {
  function_name    = "${var.project_name}-monitoring-${var.env_subfix}"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  handler          = "lambda_handler.handler"
  runtime          = var.lambda_runtime
  timeout          = 300
  memory_size      = 256
  role             = aws_iam_role.lambda.arn
  layers           = [aws_lambda_layer_version.sdk.arn]

  environment {
    variables = {
      SCRIPTS_BUCKET  = aws_s3_bucket.scripts.id
      PUSHGATEWAY_URL = var.pushgateway_url
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc,
    aws_iam_role_policy.lambda_inline,
  ]

  tags = merge(var.tags_project, {
    Name = "${var.project_name}-monitoring-${var.env_subfix}"
  })
}

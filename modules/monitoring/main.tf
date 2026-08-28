################################################################################
# Scripts bucket — the "code store" for the monitors
################################################################################

# WHY: The monitoring scripts (monitoring-scripts/*.py) are uploaded here by the
# GitHub Action on merge. The Lambda downloads the one named in the EventBridge
# event at runtime. Keeping scripts in S3 (instead of baking them into the Lambda)
# means adding/changing a monitor is a file edit + a schedule rule — no Lambda
# redeploy. The bucket name is account- and env-specific so nonprod/prod never clash.
resource "aws_s3_bucket" "scripts" {
  bucket = "monitoring-scripts-${var.aws_account_id}-${var.env_subfix}"

  tags = merge(var.tags_project, {
    Name = "${var.project_name}-monitoring-scripts-${var.env_subfix}"
  })
}

# WHY: Versioning so a broken script upload is recoverable and auditable.
resource "aws_s3_bucket_versioning" "scripts" {
  bucket = aws_s3_bucket.scripts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# WHY: Encrypt the scripts at rest (they may contain account-specific logic).
resource "aws_s3_bucket_server_side_encryption_configuration" "scripts" {
  bucket = aws_s3_bucket.scripts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# WHY: This bucket holds executable code, so it must never be publicly reachable.
resource "aws_s3_bucket_public_access_block" "scripts" {
  bucket                  = aws_s3_bucket.scripts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

################################################################################
# Lambda layer — the shared `monitoring_sdk` package
################################################################################

# WHY: Build the layer zip from src/monitoring_sdk. Every monitoring script runs
# as a subprocess and does `from monitoring_sdk import Pushgateway`, so the SDK
# must be on the Lambda PYTHONPATH. Placing it under
# python/lib/python3.12/site-packages makes Lambda expose it automatically.
data "archive_file" "layer" {
  type = "zip"

  output_path = "${path.module}/_build/layer.zip"

  source {
    content  = file("${path.module}/../../src/monitoring_sdk/__init__.py")
    filename = "python/lib/python3.12/site-packages/monitoring_sdk/__init__.py"
  }

  source {
    content  = file("${path.module}/../../src/monitoring_sdk/pushgw.py")
    filename = "python/lib/python3.12/site-packages/monitoring_sdk/pushgw.py"
  }
}

# WHY: Publish the SDK as a Lambda layer so all scripts share one copy of the
# Pushgateway client instead of each bundling it.
resource "aws_lambda_layer_version" "sdk" {
  filename            = data.archive_file.layer.output_path
  source_code_hash    = data.archive_file.layer.output_base64sha256
  layer_name          = "${var.project_name}-monitoring-sdk-${var.env_subfix}"
  compatible_runtimes = [var.lambda_runtime]
  description         = "Shared monitoring SDK (Pushgateway client)"
}

################################################################################
# Lambda function — the single dispatcher
################################################################################

# WHY: Build the deployment package from the handler + the SDK (the handler also
# imports the SDK directly so it can emit its own heartbeat metrics).
data "archive_file" "lambda" {
  type = "zip"

  output_path = "${path.module}/_build/lambda.zip"

  source {
    content  = file("${path.module}/../../src/lambda_handler.py")
    filename = "lambda_handler.py"
  }

  source {
    content  = file("${path.module}/../../src/monitoring_sdk/__init__.py")
    filename = "monitoring_sdk/__init__.py"
  }

  source {
    content  = file("${path.module}/../../src/monitoring_sdk/pushgw.py")
    filename = "monitoring_sdk/pushgw.py"
  }
}

################################################################################
# Networking — Lambda SG + ingress to the Pushgateway
################################################################################

# WHY: A dedicated SG for the Lambda. Egress is open so it can reach S3 (to fetch
# scripts) and AWS APIs over the NAT gateway; it needs no ingress because only
# EventBridge invokes it.
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

# WHY: The only network rule required to reach the in-VPC Pushgateway: open :9091
# from the Lambda SG into the Pushgateway's SG (passed in as
# pushgateway_security_group_id). This avoids reusing/modifying the grafana ECS SG.
resource "aws_security_group_rule" "pushgateway_ingress" {
  type                     = "ingress"
  security_group_id        = var.pushgateway_security_group_id
  source_security_group_id = aws_security_group.lambda.id
  from_port                = 9091
  to_port                  = 9091
  protocol                 = "tcp"
  description              = "Allow monitoring Lambda to reach the Pushgateway"
}

# WHY: The one Lambda that every EventBridge schedule rule invokes. It downloads
# the requested script from S3 and runs it; the script pushes metrics to the
# Pushgateway through the layer. It lives in the private subnets (so it can use
# the NAT to reach S3 and reach the in-VPC Pushgateway via the SG rule above).
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

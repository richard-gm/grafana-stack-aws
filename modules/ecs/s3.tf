resource "aws_s3_bucket" "prometheus_config" {
  bucket = "${var.project_name}-config-files-${var.env_subfix}"

  tags = merge(
    var.tags_project,
    {
      Name        = "Prometheus Config Bucket"
      Environment = var.env_subfix
      Project     = var.project_name
    }
  )
}

resource "aws_s3_bucket_versioning" "prometheus_config" {
  bucket = aws_s3_bucket.prometheus_config.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "prometheus_config" {
  bucket = aws_s3_bucket.prometheus_config.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "prometheus_config" {
  bucket = aws_s3_bucket.prometheus_config.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

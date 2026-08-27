resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.project_name} ${var.env_subfix} encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-kms-${var.env_subfix}"
    }
  )
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.env_subfix}"
  target_key_id = aws_kms_key.main.key_id
}

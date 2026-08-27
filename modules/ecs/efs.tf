resource "aws_efs_file_system" "prometheus" {
  creation_token = "${var.project_name}-prometheus-${var.env_subfix}"
  encrypted      = true

  tags = merge(
    var.tags_project,
    {
      Name        = "Prometheus EFS"
      Environment = var.env_subfix
      Project     = var.project_name
    }
  )
}

resource "aws_efs_mount_target" "prometheus" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.prometheus.id
  subnet_id       = element(var.private_subnet_ids, count.index)
  security_groups = [var.prometheus_efs_sg_id]
}

resource "aws_efs_access_point" "prometheus" {
  file_system_id = aws_efs_file_system.prometheus.id

  posix_user {
    uid = 1001
    gid = 1001
  }

  root_directory {
    path = "/prometheus-data"
    creation_info {
      owner_uid   = 1001
      owner_gid   = 1001
      permissions = "0775"
    }
  }

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-${var.env_subfix}-prometheus-ap"
    }
  )
}

resource "aws_efs_file_system" "grafana" {
  creation_token = "${var.project_name}-grafana-${var.env_subfix}"
  encrypted      = true

  tags = merge(
    var.tags_project,
    {
      Name        = "Grafana EFS"
      Environment = var.env_subfix
      Project     = var.project_name
    }
  )
}

resource "aws_efs_mount_target" "grafana" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.grafana.id
  subnet_id       = element(var.private_subnet_ids, count.index)
  security_groups = [var.prometheus_efs_sg_id]
}

resource "aws_efs_access_point" "grafana" {
  file_system_id = aws_efs_file_system.grafana.id

  posix_user {
    uid = 472
    gid = 472
  }

  root_directory {
    path = "/grafana-data"
    creation_info {
      owner_uid   = 472
      owner_gid   = 472
      permissions = "0775"
    }
  }

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-${var.env_subfix}-grafana-ap"
    }
  )
}

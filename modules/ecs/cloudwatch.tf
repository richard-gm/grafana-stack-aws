resource "aws_cloudwatch_log_group" "prometheus" {
  name              = "/ecs/prometheus-${var.env_subfix}"
  retention_in_days = 30

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-${var.env_subfix}-prometheus-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/grafana-${var.env_subfix}"
  retention_in_days = 30

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-${var.env_subfix}-grafana-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "pushgateway" {
  name              = "/ecs/prometheus-pushgateway-${var.env_subfix}"
  retention_in_days = 30

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-${var.env_subfix}-pushgateway-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "loki" {
  name              = "/ecs/loki-${var.env_subfix}"
  retention_in_days = 30

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-${var.env_subfix}-loki-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "mimir" {
  name              = "/ecs/mimir-${var.env_subfix}"
  retention_in_days = 30

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-${var.env_subfix}-mimir-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "tempo" {
  name              = "/ecs/tempo-${var.env_subfix}"
  retention_in_days = 30

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-${var.env_subfix}-tempo-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "otel" {
  name              = "/ecs/otel-${var.env_subfix}"
  retention_in_days = 30

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-${var.env_subfix}-otel-logs"
    }
  )
}

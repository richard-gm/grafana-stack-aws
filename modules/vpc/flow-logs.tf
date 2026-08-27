resource "aws_flow_log" "vpc_flow_log" {
  vpc_id                   = aws_vpc.main.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.vpc_flow_log.arn
  iam_role_arn             = aws_iam_role.vpc_flow_log.arn
  max_aggregation_interval = 60

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-vpc-flow-log-${var.env_subfix}"
    }
  )
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flow-log/${var.project_name}-${var.env_subfix}"
  retention_in_days = 30

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-vpc-flow-log-${var.env_subfix}"
    }
  )
}

resource "aws_iam_role" "vpc_flow_log" {
  name = "${var.project_name}-vpc-flow-log-role-${var.env_subfix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-vpc-flow-log-role-${var.env_subfix}"
    }
  )
}

resource "aws_iam_role_policy" "vpc_flow_log" {
  name = "${var.project_name}-vpc-flow-log-policy-${var.env_subfix}"
  role = aws_iam_role.vpc_flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

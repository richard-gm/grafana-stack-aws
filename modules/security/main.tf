resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg-${var.env_subfix}"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-alb-sg-${var.env_subfix}"
    }
  )
}

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg-${var.env_subfix}"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "From ALB"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "From VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-ecs-sg-${var.env_subfix}"
    }
  )
}

resource "aws_security_group" "efs_prometheus" {
  name        = "${var.project_name}-efs-prometheus-sg-${var.env_subfix}"
  description = "Security group for Prometheus EFS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS from ECS"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-efs-prometheus-sg-${var.env_subfix}"
    }
  )
}

resource "aws_security_group" "efs_grafana" {
  name        = "${var.project_name}-efs-grafana-sg-${var.env_subfix}"
  description = "Security group for Grafana EFS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS from ECS"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-efs-grafana-sg-${var.env_subfix}"
    }
  )
}

resource "aws_security_group" "nlb" {
  name        = "${var.project_name}-nlb-sg-${var.env_subfix}"
  description = "Security group for Network Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Pushgateway"
    from_port   = 9091
    to_port     = 9091
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-nlb-sg-${var.env_subfix}"
    }
  )
}

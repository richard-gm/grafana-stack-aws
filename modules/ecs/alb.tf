resource "aws_lb" "grafana" {
  name               = "grafana-alb-${var.env_subfix}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnets

  enable_deletion_protection = false

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-grafana-alb-${var.env_subfix}"
    }
  )
}

resource "aws_lb_target_group" "grafana" {
  name        = "grafana-tg-${var.env_subfix}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/login"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-299"
  }

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-grafana-tg-${var.env_subfix}"
    }
  )
}

resource "aws_lb_listener" "grafana_http" {
  load_balancer_arn = aws_lb.grafana.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}

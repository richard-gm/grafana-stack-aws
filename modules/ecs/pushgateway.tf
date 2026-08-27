resource "aws_ecs_task_definition" "pushgateway" {
  family                   = "pushgateway-${var.env_subfix}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name      = "pushgateway"
      image     = "${aws_ecr_repository.pushgateway.repository_url}:latest"
      essential = true

      environment = [
        {
          name  = "PROMETHEUS_DNS_NAME"
          value = "prometheus.${aws_service_discovery_private_dns_namespace.monitoring.name}"
        }
      ]

      portMappings = [
        {
          containerPort = 9091
          hostPort      = 9091
          protocol      = "tcp"
          name          = "pushgateway-port"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.pushgateway.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "pushgateway"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:9091/-/healthy || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
  ])
}

resource "aws_ecs_service" "pushgateway" {
  name                               = "pushgateway-${var.env_subfix}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.pushgateway.arn
  launch_type                        = "FARGATE"
  desired_count                      = 1
  enable_execute_command             = true
  health_check_grace_period_seconds  = 60

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.monitoring.arn
    service {
      port_name       = "pushgateway-port"
      discovery_name  = "pushgateway"
      client_alias {
        port     = 9091
        dns_name = "pushgateway"
      }
    }
  }

  tags = merge(
    var.tags_project,
    {
      Name = "pushgateway-${var.env_subfix}"
    }
  )
}

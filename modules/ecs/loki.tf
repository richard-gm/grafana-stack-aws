resource "aws_ecs_task_definition" "loki" {
  family                   = "loki-${var.env_subfix}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name      = "loki"
      image     = "${var.loki_repo_url}:latest"
      essential = true

      environment = [
        {
          name  = "AWS_REGION"
          value = var.region
        }
      ]

      portMappings = [
        {
          containerPort = 3100
          hostPort      = 3100
          protocol      = "tcp"
          name          = "loki-port"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.loki.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "loki"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget -q --spider http://localhost:3100/ready || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }
    }
  ])
}

resource "aws_ecs_service" "loki" {
  name                               = "loki-${var.env_subfix}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.loki.arn
  launch_type                        = "FARGATE"
  desired_count                      = 1
  enable_execute_command             = true

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.monitoring.arn
    service {
      port_name       = "loki-port"
      discovery_name  = "loki"
      client_alias {
        port     = 3100
        dns_name = "loki"
      }
    }
  }

  tags = merge(
    var.tags_project,
    {
      Name = "loki-${var.env_subfix}"
    }
  )
}

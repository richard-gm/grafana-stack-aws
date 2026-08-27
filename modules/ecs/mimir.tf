resource "aws_ecs_task_definition" "mimir" {
  family                   = "mimir-${var.env_subfix}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 512
  memory                   = 1024

  container_definitions = jsonencode([
    {
      name      = "mimir"
      image     = "${var.mimir_repo_url}:latest"
      essential = true

      environment = [
        {
          name  = "AWS_REGION"
          value = var.region
        }
      ]

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
          name          = "mimir-port"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.mimir.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "mimir"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget -q --spider http://localhost:8080/ready || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])
}

resource "aws_ecs_service" "mimir" {
  name                               = "mimir-${var.env_subfix}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.mimir.arn
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
      port_name       = "mimir-port"
      discovery_name  = "mimir"
      client_alias {
        port     = 8080
        dns_name = "mimir"
      }
    }
  }

  tags = merge(
    var.tags_project,
    {
      Name = "mimir-${var.env_subfix}"
    }
  )
}

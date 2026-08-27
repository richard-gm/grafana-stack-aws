resource "aws_ecs_task_definition" "tempo" {
  family                   = "tempo-${var.env_subfix}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name      = "tempo"
      image     = "${var.tempo_repo_url}:latest"
      essential = true

      environment = [
        {
          name  = "AWS_REGION"
          value = var.region
        }
      ]

      portMappings = [
        {
          containerPort = 3200
          hostPort      = 3200
          protocol      = "tcp"
          name          = "tempo-http-port"
        },
        {
          containerPort = 4317
          hostPort      = 4317
          protocol      = "tcp"
          name          = "tempo-grpc-port"
        },
        {
          containerPort = 4318
          hostPort      = 4318
          protocol      = "tcp"
          name          = "tempo-otlp-http-port"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.tempo.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "tempo"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget -q --spider http://localhost:3200/ready || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }
    }
  ])
}

resource "aws_ecs_service" "tempo" {
  name                               = "tempo-${var.env_subfix}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.tempo.arn
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
      port_name       = "tempo-grpc-port"
      discovery_name  = "tempo"
      client_alias {
        port     = 4317
        dns_name = "tempo"
      }
    }
  }

  tags = merge(
    var.tags_project,
    {
      Name = "tempo-${var.env_subfix}"
    }
  )
}

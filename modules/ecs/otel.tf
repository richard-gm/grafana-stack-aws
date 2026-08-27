resource "aws_ecs_task_definition" "otel" {
  family                   = "otel-${var.env_subfix}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name      = "otel-collector"
      image     = "${var.otel_repo_url}:latest"
      essential = true

      environment = [
        {
          name  = "AWS_REGION"
          value = var.region
        }
      ]

      portMappings = [
        {
          containerPort = 4317
          hostPort      = 4317
          protocol      = "tcp"
          name          = "otel-grpc-port"
        },
        {
          containerPort = 4318
          hostPort      = 4318
          protocol      = "tcp"
          name          = "otel-http-port"
        },
        {
          containerPort = 8888
          hostPort      = 8888
          protocol      = "tcp"
          name          = "otel-metrics-port"
        },
        {
          containerPort = 8889
          hostPort      = 8889
          protocol      = "tcp"
          name          = "otel-exporter-metrics-port"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.otel.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "otel"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget -q --spider http://localhost:13133/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
  ])
}

resource "aws_ecs_service" "otel" {
  name                               = "otel-${var.env_subfix}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.otel.arn
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
      port_name       = "otel-grpc-port"
      discovery_name  = "otel-collector"
      client_alias {
        port     = 4317
        dns_name = "otel-collector"
      }
    }
  }

  tags = merge(
    var.tags_project,
    {
      Name = "otel-${var.env_subfix}"
    }
  )
}

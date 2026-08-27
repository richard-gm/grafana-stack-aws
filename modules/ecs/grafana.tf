resource "aws_ecs_task_definition" "grafana" {
  family                   = "grafana-${var.env_subfix}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name      = "grafana"
      image     = "${aws_ecr_repository.grafana.repository_url}:latest"
      essential = true

      environment = [
        {
          name  = "PROMETHEUS_PRIVATE_DNS_NAME"
          value = "prometheus.${aws_service_discovery_private_dns_namespace.monitoring.name}"
        },
        {
          name  = "GF_SECURITY_ADMIN_USER"
          value = "admin"
        },
        {
          name  = "GF_SECURITY_ADMIN_PASSWORD"
          value = "admin"
        },
        {
          name  = "AWS_REGION"
          value = var.region
        }
      ]

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
          name          = "grafana-port"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "efs-grafana"
          containerPath = "/var/lib/grafana"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.grafana.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "grafana"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3000/api/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  volume {
    name = "efs-grafana"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.grafana.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.grafana.id
        iam             = "DISABLED"
      }
    }
  }
}

resource "aws_ecs_service" "grafana" {
  name                               = "grafana-${var.env_subfix}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.grafana.arn
  launch_type                        = "FARGATE"
  desired_count                      = 1
  enable_execute_command             = true

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.monitoring.arn
    service {
      port_name       = "grafana-port"
      discovery_name  = "grafana"
      client_alias {
        port     = 3000
        dns_name = "grafana"
      }
    }
  }

  depends_on = [aws_efs_mount_target.grafana, aws_lb_listener.grafana_http]

  tags = merge(
    var.tags_project,
    {
      Name = "grafana-${var.env_subfix}"
    }
  )
}

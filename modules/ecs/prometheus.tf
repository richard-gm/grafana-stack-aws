resource "aws_ecs_task_definition" "prometheus" {
  family                   = "prometheus-${var.env_subfix}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 512
  memory                   = 1024

  container_definitions = jsonencode([
    {
      name      = "prometheus"
      image     = "${aws_ecr_repository.prometheus.repository_url}:latest"
      user      = "1001:1001"
      essential = true

      environment = [
        {
          name  = "PUSHGATEWAY_PRIVATE_DNS_NAME"
          value = aws_service_discovery_private_dns_namespace.monitoring.name
        },
        {
          name  = "PROMETHEUS_CONFIG_BUCKET"
          value = aws_s3_bucket.prometheus_config.bucket
        },
        {
          name  = "AWS_REGION"
          value = var.region
        }
      ]

      portMappings = [
        {
          containerPort = 9090
          hostPort      = 9090
          protocol      = "tcp"
          name          = "prometheus-port"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "efs-prometheus"
          containerPath = "/opt/bitnami/prometheus/data"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.prometheus.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "prometheus"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:9090/-/healthy || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  volume {
    name = "efs-prometheus"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.prometheus.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.prometheus.id
        iam             = "DISABLED"
      }
    }
  }
}

resource "aws_ecs_service" "prometheus" {
  name                               = "prometheus-${var.env_subfix}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.prometheus.arn
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
      port_name       = "prometheus-port"
      discovery_name  = "prometheus"
      client_alias {
        port     = 9090
        dns_name = "prometheus"
      }
    }
  }

  depends_on = [aws_efs_mount_target.prometheus]

  tags = merge(
    var.tags_project,
    {
      Name = "prometheus-${var.env_subfix}"
    }
  )
}

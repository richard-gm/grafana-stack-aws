
resource "aws_ecr_repository" "prometheus_pushgateway_repo" {
    name = "prometheus-pushgateway-repo-${var.env_subfix}"
    tags = merge(
        var.tags_project,
        {
            Name = "ecs-prometheus-${var.env_subfix}"
        }
    )
}


####### ECS Task Definition for Prometheus ########

resource "aws_ecs_task_definition" "prometheus_pushgateway" {
    family                   = "prometheus-pushgateway-${var.env_subfix}"
    network_mode             = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    task_role_arn            = aws_iam_role.ecs_task_role.arn
    execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
    cpu                      = "256"
    memory                   = "512"

    container_definitions = jsonencode([
        {
            name      = "prometheus-pushgateway-container",
            image     = "${aws_ecr_repository.prometheus_pushgateway_repo.repository_url}:latest",
            essential = true,
            environment = [
                {
                    name  = "PROMETHEUS_DNS_NAME"
                    value = var.prometheus_nlb_dns_name
                }
            ],
            portMappings = [
                {
                    containerPort = 9091
                    hostPort      = 9091
                    protocol      = "tcp"
                    name          = "pushgateway-port"
                }
            ],
            logConfiguration = {
                logDriver = "awslogs",
                options = {
                    awslogs-group         = "/ecs/prometheus-pushgateway-${var.env_subfix}"
                    "awslogs-region"        = var.region,
                    "awslogs-stream-prefix" = "prometheus-pushgateway"
                }
            },
            healthCheck = {
                command     = ["CMD-SHELL", "curl -f http://localhost:9091/-/healthy || exit 1"]
                interval    = 30
                timeout     = 5
                retries     = 3
                startPeriod = 10
            }
        },
    ])
}

resource "aws_service_discovery_private_dns_namespace" "monitoring_dns" {
    name        = "monitoring.dns"
    description = "Service Connect namespace for monitoring stack"
    vpc         = var.vpc_id
}

resource "aws_ecs_service" "prometheus_pushgateway_service" {
    name            = "prometheus_pushgateway-${var.env_subfix}"
    cluster         = aws_ecs_cluster.ecs_prometheus-grafana-cluster.id
    task_definition = aws_ecs_task_definition.prometheus_pushgateway.arn
    launch_type     = "FARGATE"
    enable_execute_command = true
    desired_count = 1
    health_check_grace_period_seconds = 60

    network_configuration {
        subnets         = var.private_subnets
        security_groups = [var.ecs_sg_id]
        assign_public_ip = false
    }

    load_balancer {
        target_group_arn = var.prometheus_pushgateway_tg
        container_name   = "prometheus-pushgateway-container"
        container_port   = 9091
    }

    service_connect_configuration {
        enabled = true
        namespace = aws_service_discovery_private_dns_namespace.monitoring_dns.arn
        service {
            port_name = "pushgateway-port"
            discovery_name = "prometheus-pushgateway"
            client_alias {
                port     = 9091
                dns_name = "prometheus-pushgateway"
            }
        }
    }
    # Add this block to force a new deployment
    triggers = {
        force_redeploy = "v1"
    }
}


resource "aws_cloudwatch_log_group" "ecs_prometheus_pushgateway_group" {
    name              = "/ecs/prometheus-pushgateway-${var.env_subfix}"
    retention_in_days = 30 # Retain logs for 30 days (adjust as needed)

    tags = merge(
        var.tags_project,
        {
            Name = "${var.project_name}-${var.env_subfix}-logs"
        }
    )
}



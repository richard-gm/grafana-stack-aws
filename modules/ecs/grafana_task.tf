resource "aws_efs_file_system" "grafana_efs" {
    creation_token = "${var.project_name}-grafana-${var.env_subfix}"

    tags = {
        Name        = "Grafana EFS"
        Environment = var.env_subfix
        Project     = var.project_name
    }
}

resource "aws_efs_mount_target" "grafana_efs_mount_target" {
    count           = length(var.private_subnet_ids)
    file_system_id  = aws_efs_file_system.grafana_efs.id
    subnet_id       = element(var.private_subnet_ids, count.index)
    security_groups = [var.prometheus_efs_sg_id]
}

resource "aws_efs_access_point" "grafana_ap" {
    file_system_id = aws_efs_file_system.grafana_efs.id

    posix_user {
        uid = 472    # Default Grafana UID
        gid = 472    # Default Grafana GID
    }

    root_directory {
        path = "/grafana-data"
        creation_info {
            owner_uid   = 472
            owner_gid   = 472
            permissions = "0775"
        }
    }

    tags = merge(
        var.tags_project,
        {
            Name = "${var.project_name}-${var.env_subfix}-grafana-ap"
        }
    )
}



resource "aws_ecr_repository" "grafana_repo" {
    name = "grafana-repo-${var.env_subfix}"
    tags = merge(
        var.tags_project,
        {
            Name = "ecs-grafana-${var.env_subfix}"
        }
    )
}
resource "aws_ecs_task_definition" "grafana" {
    family                   = "grafana-${var.env_subfix}"
    network_mode             = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    task_role_arn            = aws_iam_role.ecs_task_role.arn
    execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
    cpu                      = "256"
    memory                   = "512"

    container_definitions = jsonencode([
        {
            name      = "grafana",
            image     = "${aws_ecr_repository.grafana_repo.repository_url}:latest",
            essential = true,
            environment = [
                {
                    name = "PROMETHEUS_PRIVATE_DNS_NAME"
                    value = var.prometheus_private_dns_name
                },
                {
                    "name": "GF_SECURITY_ADMIN_USER",
                    "value": "admin"
                },
                {
                    "name": "GF_SECURITY_ADMIN_PASSWORD",
                    "value": "admin"
                },
                {
                    "name": "AWS_REGION",
                    "value": var.region
                }
            ],
            portMappings = [
                {
                    containerPort = 3000
                    hostPort      = 3000
                    protocol      = "tcp"
                    name          = "grafana-port"
                }
            ],
            logConfiguration = {
                logDriver = "awslogs",
                options = {
                    awslogs-group         = "/ecs/grafana-${var.env_subfix}"
                    "awslogs-region"        = var.region,
                    "awslogs-stream-prefix" = "grafana"
                }
            },
            healthCheck = {
                command     = ["CMD-SHELL", "curl -f http://localhost:3000/api/health || exit 1"]
                interval    = 30
                timeout     = 5
                retries     = 3
                startPeriod = 60
            },
            mountPoints = [
                {
                    sourceVolume  = "grafana-efs"
                    containerPath = "/var/lib/grafana"
                    readOnly      = false
                }
            ],
        }
    ])
    volume {
        name = "grafana-efs"
        efs_volume_configuration {
            file_system_id = aws_efs_file_system.grafana_efs.id
            root_directory = "/"
            transit_encryption = "ENABLED" # Enable encryption in transit
            authorization_config {
                access_point_id = aws_efs_access_point.grafana_ap.id
                iam             = "DISABLED" # Use IAM for EFS access control
            }
        }
    }
}



resource "aws_cloudwatch_log_group" "ecs_task_log_group_grafana" {
    name              = "/ecs/grafana-${var.env_subfix}"
    retention_in_days = 30 # Retain logs for 30 days (adjust as needed)

    tags = merge(
        var.tags_project,
        {
            Name = "${var.project_name}-${var.env_subfix}-logs"
        }
    )
}

# Update the Grafana ECS Service to Use the Load Balancer
resource "aws_ecs_service" "grafana_service" {
    name            = "grafana_task-${var.env_subfix}"
    cluster         = aws_ecs_cluster.ecs_prometheus-grafana-cluster.id
    task_definition = aws_ecs_task_definition.grafana.arn
    launch_type     = "FARGATE"
    desired_count   = 1
    enable_execute_command = true

    network_configuration {
        subnets         = var.private_subnets
        security_groups = [var.ecs_sg_id]
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.grafana_tg.arn
        container_name   = "grafana"
        container_port   = 3000 # Grafana container port
    }

    service_connect_configuration {
        enabled = true
        namespace = aws_service_discovery_private_dns_namespace.monitoring_dns.arn
        service {
            port_name = "grafana-port"
            discovery_name = "grafana"
            client_alias {
                port     = 3000
                dns_name = "grafana"
            }
        }
    }

    tags = merge(
        var.tags_project,
        {
            Name = "grafana-service-${var.env_subfix}"
        }
    )
}

# Create a Target Group for the ECS Service
resource "aws_lb_target_group" "grafana_tg" {
    name        = "grafana-tg-${var.env_subfix}"
    port        = 3000 # Grafana default port
    protocol    = "HTTP"
    vpc_id      = var.vpc_id
    target_type = "ip" # For ECS on Fargate

    health_check {
        path                = "/login" # Update the health check path
        interval            = 30       # Check every 30 seconds
        timeout             = 5        # Timeout after 5 seconds
        healthy_threshold   = 3        # Mark healthy after 3 successful checks
        unhealthy_threshold = 3        # Mark unhealthy after 3 failed checks
        matcher             = "200-299" # Look for HTTP 2xx responses
    }

    tags = merge(
        var.tags_project,
        {
            Name = "${var.project_name}-grafana-tg-${var.env_subfix}"
        }
    )
}



# Create the Application Load Balancer
resource "aws_lb" "grafana_alb" {
    name               = "grafana-alb-${var.env_subfix}"
    internal           = false # Public ALB
    load_balancer_type = "application"
    security_groups    = [var.alb_sg_id]
    subnets            = var.public_subnets # Use public subnets

    enable_deletion_protection = false

    tags = merge(
        var.tags_project,
        {
            Name = "${var.project_name}-grafana-alb-${var.env_subfix}"
        }
    )
}

# # Create a Listener for the Load Balancer
resource "aws_lb_listener" "grafana_listener" {
    load_balancer_arn = aws_lb.grafana_alb.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.grafana_tg.arn
    }
}

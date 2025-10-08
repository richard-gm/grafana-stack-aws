resource "aws_ecs_cluster" "ecs_prometheus-grafana-cluster" {
    name = "${var.project_name}-${var.env_subfix}"

    configuration {
        execute_command_configuration {
            logging = "DEFAULT" # Enables ECS Exec and logs execution activity to CloudWatch
        }
    }

    tags = merge(
        var.tags_project,
        {
            Name = "ecs-prometheus-${var.env_subfix}"
        }
    )
}

resource "aws_ecr_repository" "prometheus_repo" {
    name = "prometheus-repo-${var.env_subfix}"
    tags = merge(
        var.tags_project,
        {
            Name = "ecs-prometheus-${var.env_subfix}"
        }
    )
}


resource "aws_efs_file_system" "prometheus" {
    creation_token = "${var.project_name}-prometheus-${var.env_subfix}"

    tags = {
        Name        = "Prometheus EFS"
        Environment = var.env_subfix
        Project     = var.project_name
    }
}

resource "aws_efs_mount_target" "prometheus" {
    count           = length(var.private_subnet_ids)
    file_system_id  = aws_efs_file_system.prometheus.id
    subnet_id       = element(var.private_subnet_ids, count.index)
    security_groups = [var.prometheus_efs_sg_id]

}

resource "aws_efs_access_point" "prometheus_ap" {
    file_system_id = aws_efs_file_system.prometheus.id

    posix_user {
        uid = 1001
        gid = 1001
    }

    root_directory {
        path = "/prometheus-data"
        creation_info {
            owner_uid   = 1001
            owner_gid   = 1001
            permissions = "0775"
        }
    }
    tags = merge(
        var.tags_project,
        {
            Name = "${var.project_name}-${var.env_subfix}-logs"
        }
    )
}


resource "aws_s3_bucket" "prometheus_config" {
    bucket = "${var.project_name}-config-files-${var.env_subfix}"
    tags = {
        Name        = "Prometheus Config Bucket"
        Environment = var.env_subfix
        Project     = var.project_name
    }
}


####### ECS Task Definition for Prometheus ########

resource "aws_ecs_task_definition" "prometheus" {
    family             = "prometheus-${var.env_subfix}"
    network_mode       = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    task_role_arn      = aws_iam_role.ecs_task_role.arn  # Changed back to the role with all permissions
    execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
    cpu                = "512"
    memory             = "1024"

    container_definitions = jsonencode([
        {
            name      = "prometheus-container",
            image     = "${aws_ecr_repository.prometheus_repo.repository_url}:latest",
            user      = "1001:1001"
            essential = true,
            environment = [
                {
                    name  = "PUSHGATEWAY_PRIVATE_DNS_NAME"
                    value = var.pushgateway_private_dns_name
                },
                {
                    name  = "PROMETHEUS_CONFIG_BUCKET"
                    value = aws_s3_bucket.prometheus_config.bucket
                },
                {
                    name  = "CONFIG_UPDATE_QUEUE_URL"
                    value = aws_sqs_queue.prometheus_config_updates.url
                },
                {
                    name  = "AWS_REGION"
                    value = var.region
                },
                {
                    name  = "ENABLE_TIMESTREAM_ADAPTER"
                    value = "true"
                },
                {
                    name  = "TIMESTREAM_DATABASE_NAME"
                    value = aws_timestreamwrite_database.prometheus_db.database_name
                },
                {
                    name  = "TIMESTREAM_TABLE_NAME"
                    value = aws_timestreamwrite_table.prometheus_metrics.table_name
                },
                {
                    name  = "TIMESTREAM_ADAPTER_PORT"
                    value = "9201"
                },
                {
                    name  = "TIMESTREAM_DEBUG"
                    value = "false"
                },
                {
                    name  = "Test"
                    value = "test-delete_0"
                },
                {
                    name  = "TS_DEDUP_ENABLED"
                    value = var.ts_dedup_enabled ? "true" : "false"
                },
                {
                    name  = "TS_MIN_WRITE_INTERVAL_SECONDS"
                    value = tostring(var.ts_min_write_interval_seconds)
                },
                {
                    name  = "TS_VALUE_CHANGE_EPSILON"
                    value = tostring(var.ts_value_change_epsilon)
                },
                {
                    name  = "TS_VALUE_CHANGE_REL_EPSILON"
                    value = tostring(var.ts_value_change_rel_epsilon)
                },
                {
                    name  = "TS_DEDUP_CACHE_MAX_SIZE"
                    value = tostring(var.ts_dedup_cache_max_size)
                }
            ],
            mountPoints = [
                {
                    sourceVolume  = "efs-prometheus"
                    containerPath = "/opt/bitnami/prometheus/data"
                    readOnly      = false
                }
            ],
            portMappings = [
                {
                    containerPort = 9090
                    hostPort      = 9090
                    protocol      = "tcp"
                    name          = "prometheus-port"
                }
            ],
            logConfiguration = {
                logDriver = "awslogs",
                options = {
                    awslogs-group           = "/ecs/prometheus-${var.env_subfix}"
                    "awslogs-region"        = var.region,
                    "awslogs-stream-prefix" = "prometheus-logs"
                    }
                },
            # Healthcheck needed t
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
                access_point_id = aws_efs_access_point.prometheus_ap.id
                iam             = "DISABLED"
            }
        }
    }
}



resource "aws_ecs_service" "prometheus" {
    name            = "prometheus_task-${var.env_subfix}"
    cluster         = aws_ecs_cluster.ecs_prometheus-grafana-cluster.id
    task_definition = aws_ecs_task_definition.prometheus.arn
    launch_type     = "FARGATE"
    desired_count = 1
    # this enables ECS Exec for the service "aws ecs execute-command" to ssh into the container
    enable_execute_command = true
    health_check_grace_period_seconds = 60



    network_configuration {
        subnets         = var.private_subnet_ids
        security_groups = [var.ecs_sg_id]
        assign_public_ip = false  # Changed from true to false for private subnet deployment
    }
    service_connect_configuration {
        enabled = true
        namespace = aws_service_discovery_private_dns_namespace.monitoring_dns.arn
        service {
            port_name = "prometheus-port"
            discovery_name = "prometheus"
            client_alias {
                port     = 9090
                dns_name = "prometheus"
            }
        }
    }


    tags = merge(
        var.tags_project,
        {
            Name = "${var.project_name}-${var.env_subfix}-logs"
        }
    )
}

resource "aws_cloudwatch_log_group" "ecs_task_log_group" {
    name              = "/ecs/prometheus-${var.env_subfix}"
    retention_in_days = 30 # Retain logs for 30 days (adjust as needed)

    tags = merge(
        var.tags_project,
        {
            Name = "${var.project_name}-${var.env_subfix}-logs"
        }
    )
}

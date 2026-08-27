resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.env_subfix}"

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-ecs-${var.env_subfix}"
    }
  )
}

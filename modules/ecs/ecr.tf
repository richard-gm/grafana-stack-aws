resource "aws_ecr_repository" "prometheus" {
  name                 = "prometheus-repo-${var.env_subfix}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    var.tags_project,
    {
      Name = "prometheus-repo-${var.env_subfix}"
    }
  )
}

resource "aws_ecr_repository" "grafana" {
  name                 = "grafana-repo-${var.env_subfix}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    var.tags_project,
    {
      Name = "grafana-repo-${var.env_subfix}"
    }
  )
}

resource "aws_ecr_repository" "pushgateway" {
  name                 = "prometheus-pushgateway-repo-${var.env_subfix}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    var.tags_project,
    {
      Name = "pushgateway-repo-${var.env_subfix}"
    }
  )
}

resource "aws_ecr_lifecycle_policy" "prometheus" {
  repository = aws_ecr_repository.prometheus.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "grafana" {
  repository = aws_ecr_repository.grafana.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "pushgateway" {
  repository = aws_ecr_repository.pushgateway.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_repository" "loki_repo" {
  name                 = "loki-repo-${var.env_subfix}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    var.tags_project,
    {
      Name = "loki-repo-${var.env_subfix}"
    }
  )
}

resource "aws_ecr_repository" "grafana_repo" {
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

resource "aws_ecr_repository" "mimir_repo" {
  name                 = "mimir-repo-${var.env_subfix}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    var.tags_project,
    {
      Name = "mimir-repo-${var.env_subfix}"
    }
  )
}

resource "aws_ecr_repository" "tempo_repo" {
  name                 = "tempo-repo-${var.env_subfix}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    var.tags_project,
    {
      Name = "tempo-repo-${var.env_subfix}"
    }
  )
}

resource "aws_ecr_repository" "otel_repo" {
  name                 = "otel-repo-${var.env_subfix}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    var.tags_project,
    {
      Name = "otel-repo-${var.env_subfix}"
    }
  )
}

resource "aws_ecr_lifecycle_policy" "loki_lifecycle" {
  repository = aws_ecr_repository.loki_repo.name

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

resource "aws_ecr_lifecycle_policy" "grafana_lifecycle" {
  repository = aws_ecr_repository.grafana_repo.name

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

resource "aws_ecr_lifecycle_policy" "mimir_lifecycle" {
  repository = aws_ecr_repository.mimir_repo.name

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

resource "aws_ecr_lifecycle_policy" "tempo_lifecycle" {
  repository = aws_ecr_repository.tempo_repo.name

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

resource "aws_ecr_lifecycle_policy" "otel_lifecycle" {
  repository = aws_ecr_repository.otel_repo.name

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

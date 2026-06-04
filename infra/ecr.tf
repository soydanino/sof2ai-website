resource "aws_ecr_repository" "users_api" {
  name                 = "${var.project_name}/users-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_ecr_repository" "posts_api" {
  name                 = "${var.project_name}/posts-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_ecr_repository" "comments_api" {
  name                 = "${var.project_name}/comments-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_ecr_repository" "notifications_api" {
  name                 = "${var.project_name}/notifications-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

locals {
  lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "users_api" {
  repository = aws_ecr_repository.users_api.name
  policy     = local.lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "posts_api" {
  repository = aws_ecr_repository.posts_api.name
  policy     = local.lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "comments_api" {
  repository = aws_ecr_repository.comments_api.name
  policy     = local.lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "notifications_api" {
  repository = aws_ecr_repository.notifications_api.name
  policy     = local.lifecycle_policy
}

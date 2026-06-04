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

resource "aws_ecr_lifecycle_policy" "keep_last_10" {
  for_each   = toset(["users_api", "posts_api", "comments_api", "notifications_api"])
  repository = lookup({
    users_api         = aws_ecr_repository.users_api.name
    posts_api         = aws_ecr_repository.posts_api.name
    comments_api      = aws_ecr_repository.comments_api.name
    notifications_api = aws_ecr_repository.notifications_api.name
  }, each.key)

  policy = jsonencode({
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

output "ec2_public_ip" {
  description = "Public IP of the EC2 app server"
  value       = aws_instance.app.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 app server"
  value       = aws_instance.app.public_dns
}

output "s3_bucket_name" {
  description = "Name of the S3 assets bucket"
  value       = aws_s3_bucket.assets.bucket
}

output "s3_bucket_domain" {
  description = "Domain of the S3 assets bucket"
  value       = aws_s3_bucket.assets.bucket_regional_domain_name
}

output "sqs_queue_url" {
  description = "URL of the main SQS events queue"
  value       = aws_sqs_queue.events.url
}

output "sqs_dlq_url" {
  description = "URL of the SQS dead-letter queue"
  value       = aws_sqs_queue.dlq.url
}

output "ecr_users_api_url" {
  description = "ECR repository URL for users-api"
  value       = aws_ecr_repository.users_api.repository_url
}

output "ecr_posts_api_url" {
  description = "ECR repository URL for posts-api"
  value       = aws_ecr_repository.posts_api.repository_url
}

output "ecr_comments_api_url" {
  description = "ECR repository URL for comments-api"
  value       = aws_ecr_repository.comments_api.repository_url
}

output "ecr_notifications_api_url" {
  description = "ECR repository URL for notifications-api"
  value       = aws_ecr_repository.notifications_api.repository_url
}

output "lambda_function_arn" {
  description = "ARN of the validator Lambda function"
  value       = aws_lambda_function.validator.arn
}

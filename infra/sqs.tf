resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project_name}-events-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_sqs_queue" "events" {
  name                       = "${var.project_name}-events"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400 # 1 day
  receive_wait_time_seconds  = 0

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# No queue resource policy needed: same-account access is governed by the
# EC2 IAM role policy in iam.tf (sqs:SendMessage/ReceiveMessage/DeleteMessage).
# A resource policy here would create a circular dependency with iam.tf.

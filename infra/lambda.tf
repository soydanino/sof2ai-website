data "archive_file" "validator" {
  type        = "zip"
  source_file = "${path.module}/../validator/index.js"
  output_path = "${path.module}/../validator/validator.zip"
}

resource "aws_lambda_function" "validator" {
  function_name    = "${var.project_name}-validator"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.validator.output_path
  source_code_hash = data.archive_file.validator.output_base64sha256
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      PROJECT = var.project_name
    }
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn                   = aws_sqs_queue.events.arn
  function_name                      = aws_lambda_function.validator.arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 5
  enabled                            = true
}

resource "aws_cloudwatch_log_group" "validator_logs" {
  name              = "/aws/lambda/${aws_lambda_function.validator.function_name}"
  retention_in_days = 7

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

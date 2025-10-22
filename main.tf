terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = "tfproject"
  region  = "us-west-2"
}

resource "aws_dynamodb_table" "reminder_table" {
  name         = "DailyReminders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "reminderId"

  attribute {
    name = "reminderId"
    type = "S"
  }

  attribute {
    name = "dueDate"
    type = "S"
  }

  global_secondary_index {
    name            = "DueDateIndex"
    hash_key        = "dueDate"
    projection_type = "ALL"
  }
}

resource "aws_sns_topic" "reminder_topic" {
  name = "daily-task-reminder-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.reminder_topic.arn
  protocol  = "email"
  endpoint  = "jellopops@gmail.com"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "daily-task-reminder-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name = "daily-task-reminder-permissions"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sns:publish"
        Resource = aws_sns_topic.reminder_topic.arn
      },
      {
        Effect   = "Allow"
        Action   = "dynamodb:Scan"
        Resource = aws_dynamodb_table.reminder_table.arn
      },
      {
        Effect = "Allow"
        Action = "dynamodb:Query"
        Resource = [
          aws_dynamodb_table.reminder_table.arn,
          "${aws_dynamodb_table.reminder_table.arn}/index/DueDateIndex"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/function.zip"
}

resource "aws_lambda_function" "scheduled_event_logger" {
  function_name = "daily-task-reminder"
  description   = "A lambda function that logs the payload of messages..."

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  handler       = "handlers/scheduled-event-logger.scheduledEventLoggerHandler"
  runtime       = "nodejs22.x"
  architectures = ["x86_64"]
  memory_size   = 128
  timeout       = 100

  role = aws_iam_role.lambda_exec_role.arn

  environment {
    variables = {
      SNS_TOPIC_ARN  = aws_sns_topic.reminder_topic.arn
      REMINDER_TABLE = aws_dynamodb_table.reminder_table.name
    }
  }

  logging_config {
    log_format = "JSON"
  }
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "daily-task-reminder-schedule"
  description         = "Triggers the daily task reminder Lambda function every day at 9 AM UTC"
  schedule_expression = "cron(0 14 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.scheduled_event_logger.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduled_event_logger.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}

output "lambda_function_arn" {
  description = "Daily Reminder Lambda Function ARN"
  value       = aws_lambda_function.scheduled_event_logger.arn
}

output "aws_sns_topic" {
  description = "SNS Topic for reminders"
  value       = aws_sns_topic.reminder_topic.arn
}

output "dynamodb_table_name" {
  description = "Reminder DynamoDB Table Name"
  value       = aws_dynamodb_table.reminder_table.name
}

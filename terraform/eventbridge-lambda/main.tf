terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "local" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "eventbridge-lambda-demo"
      ManagedBy   = "terraform"
    }
  }
}

module "lambda_function" {
  source = "./modules/lambda"

  environment         = var.environment
  function_name       = "eventbridge-processor-${var.environment}"
  handler            = "index.handler"
  runtime            = "nodejs20.x"
  timeout            = 30
  memory_size        = 256

  environment_vars = {
    ENVIRONMENT = var.environment
    LOG_LEVEL   = "info"
  }
}

module "eventbridge_bus" {
  source = "./modules/eventbridge"

  environment         = var.environment
  lambda_function_arn = module.lambda_function.function_arn

  event_pattern = {
    "source" : ["aws.ec2", "aws.s3", "custom.app"],
    "detail-type" : [
      "AWS API Call via CloudTrail",
      "AWS EC2 Instance State-change Notification",
      "AWS S3 Object Creation"
    ]
  }
}

resource "aws_s3_bucket" "event_bucket" {
  bucket = "eventbridge-events-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Environment = var.environment
    Project     = "eventbridge-lambda-demo"
  }
}

resource "aws_s3_bucket_versioning" "event_bucket" {
  bucket = aws_s3_bucket.event_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption" "event_bucket" {
  bucket = aws_s3_bucket.event_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge_bus.rule_arn
}

data "aws_caller_identity" "current" {}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda_function.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda_function.function_arn
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule"
  value       = module.eventbridge_bus.rule_arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for event storage"
  value       = aws_s3_bucket.event_bucket.id
}
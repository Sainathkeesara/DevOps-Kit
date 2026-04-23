variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to invoke"
  type        = string
}

variable "event_pattern" {
  description = "EventBridge event pattern"
  type        = any
  default     = {}
}

variable "schedule_expression" {
  description = "EventBridge schedule expression (optional)"
  type        = string
  default     = ""
}

output "rule_arn" {
  description = "ARN of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.this.arn
}

output "rule_name" {
  description = "Name of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.this.name
}

resource "aws_cloudwatch_event_rule" "this" {
  name           = "eventbridge-lambda-trigger-${var.environment}"
  description    = "EventBridge rule to trigger Lambda for ${var.environment}"
  event_bus_name = "default"

  dynamic "event_pattern" {
    for_each = var.event_pattern != {} ? [var.event_pattern] : []
    content {
      jsonencode(event_pattern.value)
    }
  }

  dynamic "schedule_expression" {
    for_each = var.schedule_expression != "" ? [var.schedule_expression] : []
    content {
      schedule_expression = schedule_expression.value
    }
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_event_target" "this" {
  rule           = aws_cloudwatch_event_rule.this.name
  target_id      = "lambda-target"
  arn            = var.lambda_function_arn
  input_transformer {
    input_paths    = {}
    input_template = <<EOF
{
  "environment": "${var.environment}",
  "detail": <detail>,
  "id": <id>,
  "source": <source>,
  "time": <time>
}
EOF
  }
}
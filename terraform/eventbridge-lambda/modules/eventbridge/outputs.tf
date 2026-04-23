output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.this.arn
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.this.name
}

output "event_target_id" {
  description = "ID of the EventBridge target"
  value       = aws_cloudwatch_event_target.this.target_id
}
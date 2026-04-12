# Terraform Outputs for Lambda with API Gateway

output "api_endpoint" {
  description = "Base URL of the API Gateway stage"
  value       = aws_api_gateway_stage.api.invoke_url
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_api_gateway_rest_api.api.id
}

output "api_gateway_arn" {
  description = "API Gateway ARN"
  value       = aws_api_gateway_rest_api.api.arn
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.lambda.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.lambda.arn
}

output "lambda_role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_exec.arn
}

output "s3_bucket_name" {
  description = "S3 bucket name for Lambda ZIP"
  value       = aws_s3_bucket.lambda_bucket.id
}
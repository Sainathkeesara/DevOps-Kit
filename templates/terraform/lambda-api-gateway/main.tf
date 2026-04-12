# Terraform Lambda with API Gateway Template
# This is a template project - see the full documentation at:
# terraform-lambda-api-gateway.md

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "lambda-api-gateway"
      ManagedBy   = "Terraform"
    }
  }
}

# S3 Bucket for Lambda ZIP
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "${var.project_name}-${var.environment}-lambda-${var.aws_region}"
  
  tags = var.common_tags
}

resource "aws_s3_bucket_versioning" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Upload Lambda ZIP
resource "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "lambda_function.zip"
  source = var.lambda_zip_path
  
  etag = filemd5(var.lambda_zip_path)
}

# Lambda Function
resource "aws_lambda_function" "lambda" {
  function_name    = "${var.project_name}-${var.environment}"
  runtime         = var.lambda_runtime
  handler         = var.lambda_handler
  memory_size     = var.lambda_memory
  timeout         = var.lambda_timeout
  filename        = null
  source_code_hash = data.archive_file.lambda.output_base64sha256
  
  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_zip.key
  
  role = aws_iam_role.lambda_exec.arn
  
  environment {
    variables = var.lambda_environment
  }
  
  tracing_config {
    mode = "Active"
  }
  
  depends_on = [aws_iam_role_policy_attachment.lambda_policy]
  
  tags = var.common_tags
}

data "archive_file" "lambda" {
  type        = "zip"
  output_path = "/tmp/lambda_function.zip"
  
  source {
    content = var.lambda_source_code
    filename = "index.js"
  }
}

# Lambda Execution Role
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-${var.environment}-lambda-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.project_name}-${var.environment}-api"
  description = "API Gateway for Lambda function"
  
  tags = var.common_tags
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part  = "{proxy+}"
}

resource "aws_api_gateway_method" "any" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id  = aws_api_gateway_resource.proxy.id
  http_method  = "ANY"
  authorization = "NONE"
  
  request_parameters {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.any.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
  
  passthrough_behavior = "WHEN_NO_MATCH"
  
  credentials = aws_iam_role.api_gateway_exec.arn
}

resource "aws_iam_role" "api_gateway_exec" {
  name = "${var.project_name}-${var.environment}-apigw-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "api_gateway_invoke" {
  name = "${var.project_name}-${var.environment}-apigw-invoke"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["lambda:InvokeFunction"]
      Resource = aws_lambda_function.lambda.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_policy" {
  role       = aws_iam_role.api_gateway_exec.name
  policy_arn = aws_iam_policy.api_gateway_invoke.arn
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Root resource for health check
resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = var.api_stage
}

resource "aws_api_gateway_method" "root_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id  = aws_api_gateway_resource.root.id
  http_method  = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root_lambda" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.root_get.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
  
  credentials = aws_iam_role.api_gateway_exec.arn
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  
  lifecycle {
    create_before_destroy = true
  }
  
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.root_lambda
  ]
}

resource "aws_api_gateway_stage" "api" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name   = var.api_stage
  
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format         = "$context.requestId: $context.endpoint $context.httpMethod $context.status $context.responseLatency"
  }
  
  tags = var.common_tags
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = 7
  
  tags = var.common_tags
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}"
  retention_in_days = 7
  
  tags = var.common_tags
}

# Outputs
output "api_endpoint" {
  description = "Base URL of the API Gateway"
  value       = aws_api_gateway_stage.api.invoke_url
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.lambda.arn
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.api.id
}
# Terraform Variables for Lambda with API Gateway

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "my-api"
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
  default     = "dev"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_handler" {
  description = "Lambda handler function"
  type        = string
  default     = "index.handler"
}

variable "lambda_memory" {
  description = "Lambda memory in MB"
  type        = number
  default     = 256
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_zip_path" {
  description = "Path to Lambda ZIP file"
  type        = string
  default     = "./lambda_function.zip"
}

variable "lambda_source_code" {
  description = "Lambda function source code"
  type        = string
  default     = <<-EOT
exports.handler = async (event) => {
  const response = {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*"
    },
    body: JSON.stringify({
      message: "Hello from Lambda!",
      timestamp: new Date().toISOString(),
      path: event.path,
      method: event.httpMethod
    })
  };
  return response;
};
EOT
}

variable "lambda_environment" {
  description = "Lambda environment variables"
  type        = map(string)
  default     = {
    ENVIRONMENT = "dev"
    LOG_LEVEL   = "info"
  }
}

variable "api_stage" {
  description = "API Gateway stage name"
  type        = string
  default     = "v1"
}

variable "common_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {
    ManagedBy = "Terraform"
    Project   = "lambda-api-gateway"
  }
}
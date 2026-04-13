# Terraform Lambda with API Gateway

## Purpose

Deploy a serverless API using AWS Lambda and API Gateway via Terraform. This project covers function creation, API Gateway setup, custom domain, integration with DynamoDB, and production-ready configurations including monitoring, logging, and security.

## When to use

- Building RESTful APIs without managing servers
- Creating event-driven architectures that scale automatically
- Migrating from monolithic applications to microservices
- Implementing serverless backends for web and mobile applications

## Prerequisites

### AWS Requirements
- AWS account with appropriate IAM permissions
- AWS CLI configured with credentials
- Domain name registered in Route 53 (optional for custom domain)

### Software Requirements
- Terraform >= 1.0 installed
- AWS provider >= 4.0
- curl or similar for testing

### Knowledge Requirements
- Basic understanding of Terraform syntax
- Familiarity with AWS Lambda and API Gateway concepts
- Understanding of IAM roles and policies

## Steps

### 1. Create Project Directory Structure

```bash
mkdir -p terraform-lambda-api
cd terraform-lambda-api
mkdir -p modules/lambda modules/apigateway modules/dynamodb
```

### 2. Configure Provider and Variables

Create `provider.tf`:

```hcl
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
    }
  }
}
```

Create `variables.tf`:

```hcl
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "api-handler"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs20.x"
}

variable "memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 256
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}
```

### 3. Create Lambda Function Module

Create `modules/lambda/main.tf`:

```hcl
resource "aws_iam_role" "lambda_exec" {
  name = "${var.function_name}-role-${var.environment}"

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

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "this" {
  filename         = var.zip_file
  function_name    = var.function_name
  role            = aws_iam_role.lambda_exec.arn
  handler         = var.handler
  runtime         = var.runtime
  source_code_hash = var.source_code_hash
  memory_size      = var.memory_size
  timeout          = var.timeout
  environment {
    variables = var.environment_variables
  }

  tags = var.tags
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = var.api_gateway_execution_arn
}
```

Create `modules/lambda/variables.tf`:

```hcl
variable "function_name" { type = string }
variable "runtime" { type = string }
variable "handler" { type = string }
variable "zip_file" { type = string }
variable "source_code_hash" { type = string }
variable "memory_size" { type = number }
variable "timeout" { type = number }
variable "environment_variables" { type = map(string) }
variable "api_gateway_execution_arn" { type = string }
variable "tags" { type = map(string) }
variable "environment" { type = string }
```

Create `modules/lambda/outputs.tf`:

```hcl
output "function_arn" {
  value = aws_lambda_function.this.arn
}

output "function_name" {
  value = aws_lambda_function.this.function_name
}

output "invoke_arn" {
  value = aws_lambda_function.this.invoke_arn
}
```

### 4. Create API Gateway Module

Create `modules/apigateway/main.tf`:

```hcl
resource "aws_api_gateway_rest_api" "this" {
  name        = "${var.api_name}-${var.environment}"
  description = "Lambda API Gateway for ${var.environment}"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
  tags = var.tags
}

resource "aws_api_gateway_resource" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = var.resource_path
}

resource "aws_api_gateway_method" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.this.id
  http_method   = var.http_method
  authorization = var.authorization
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  depends_on = [aws_api_gateway_integration.lambda]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.stage_name
  
  access_log_settings {
    destination_arn = var.cloudwatch_log_arn
    format         = "$context.requestId: $context.endpoint $context.httpMethod $context.status $context.responseLatency"
  }
}

resource "aws_api_gateway_domain_name" "this" {
  count = var.domain_name != "" ? 1 : 0
  
  domain_name              = var.domain_name
  regional_certificate_arn = var.certificate_arn
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "this" {
  count = var.domain_name != "" ? 1 : 0
  
  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  domain_name = aws_api_gateway_domain_name.this[0].domain_name
}
```

### 5. Create Main Configuration

Create `main.tf`:

```hcl
module "lambda" {
  source = "./modules/lambda"

  function_name            = var.function_name
  runtime                  = var.runtime
  handler                  = "index.handler"
  zip_file                 = data.archive_file.lambda_zip.output_path
  source_code_hash         = data.archive_file.lambda_zip.output_base64sha256
  memory_size              = var.memory_size
  timeout                  = var.timeout
  environment_variables    = var.environment_variables
  api_gateway_execution_arn = module.apigateway.execution_arn
  tags                     = var.tags
  environment              = var.environment
}

module "apigateway" {
  source = "./modules/apigateway"

  api_name              = var.api_name
  environment           = var.environment
  resource_path         = var.api_resource_path
  http_method           = var.http_method
  authorization         = var.authorization
  lambda_invoke_arn     = module.lambda.invoke_arn
  stage_name            = var.stage_name
  domain_name           = var.domain_name
  certificate_arn       = var.certificate_arn
  cloudwatch_log_arn    = var.cloudwatch_log_arn
  tags                  = var.tags
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda-function.zip"

  depends_on = [null_resource.package]
}

resource "null_resource" "package" {
  triggers = {
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${path.module}/src
      cat > ${path.module}/src/index.js << 'EOF'
const AWS = require('aws-sdk');
const dynamo = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  const response = {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      message: "Lambda API Gateway working",
      timestamp: new Date().toISOString(),
      method: event.httpMethod,
      path: event.path
    })
  };
  return response;
};
EOF
    EOT
  }
}
```

### 6. Add Outputs

Create `outputs.tf`:

```hcl
output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = module.lambda.function_arn
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL"
  value       = "https://${module.apigateway.stage_invoke_url}"
}

output "api_gateway_execution_arn" {
  description = "API Gateway execution ARN for Lambda permission"
  value       = module.apigateway.execution_arn
}
```

### 7. Initialize and Deploy

```bash
terraform init
terraform plan -var="environment=prod"
terraform apply -var="environment=prod" -auto-approve
```

## Verify

### Verify Lambda Function

```bash
aws lambda get-function --function-name api-handler-prod
```

Expected output shows function configuration and runtime.

### Verify API Gateway

```bash
aws apigatewayv2 get-api --api-id <api-id>
```

### Test API Endpoint

```bash
curl https://<api-id>.execute-api.<region>.amazonaws.com/prod/
```

Expected response:
```json
{
  "message": "Lambda API Gateway working",
  "timestamp": "2026-04-13T...",
  "method": "GET",
  "path": "/"
}
```

### Verify CloudWatch Logs

```bash
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/api-handler
```

## Rollback

### Remove Resources

```bash
terraform destroy -var="environment=prod" -auto-approve
```

### Revert to Previous Version

```bash
terraform apply -var="environment=prod" -var="function_name=api-handler-old" -auto-approve
```

### Rollback Lambda Version

```bash
aws lambda publish-version --function-name api-handler-prod --description "Rolled back to previous version"
```

## Common errors

### "Lambda function not found"

**Problem:** API Gateway cannot invoke Lambda function.

**Solution:**
```bash
aws lambda add-permission --function-name api-handler-prod \
  --statement-id apigateway \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:123456789012:/*"
```

### "Invalid permissions on Lambda function"

**Problem:** API Gateway lacks invoke permissions.

**Solution:** Ensure Lambda resource policy allows API Gateway:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "AllowAPIGatewayInvoke",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "lambda:InvokeFunction",
    "Resource": "arn:aws:lambda:us-east-1:123456789012:function:api-handler-prod",
    "Condition": {
      "ArnLike": {
        "aws:SourceArn": "arn:aws:execute-api:us-east-1:123456789012:*"
      }
    }
  }]
}
```

### "API Gateway deployment failed"

**Problem:** Integration timeout or configuration error.

**Solution:**
```bash
aws apigateway get-deployment --rest-api-id <api-id> --deployment-id <deployment-id>
```

Check CloudWatch logs for integration errors:
```bash
aws logs filter-log-events --log-group-name /aws/apigateway/<api-id>-access-logs
```

### "CORS errors"

**Problem:** Missing CORS headers on Lambda response.

**Solution:** Add CORS headers to Lambda response:
```javascript
return {
  statusCode: 200,
  headers: {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,Authorization",
    "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS"
  },
  body: JSON.stringify({ message: "Success" })
};
```

## References

- AWS Lambda Documentation: https://docs.aws.amazon.com/lambda/
- AWS API Gateway Documentation: https://docs.aws.amazon.com/apigateway/
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Lambda Performance Tuning: https://aws.amazon.com/blogs/compute/optimizing-python-runtime-in-aws-lambda/
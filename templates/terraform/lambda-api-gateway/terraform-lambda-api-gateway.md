# Terraform Lambda with API Gateway Project

## Purpose

This project provides infrastructure-as-code for deploying a serverless REST API using AWS Lambda and API Gateway. The template includes function code, API Gateway setup, IAM roles, and security configurations.

## When to use

- Build serverless APIs without managing servers
- Create HTTP-triggered Lambda functions
- Implement API versioning and throttling
- Need scalable, pay-per-request backends
- Integrate with AWS SAM or use raw Terraform

## Prerequisites

- AWS account with appropriate permissions
- Terraform >= 1.0 installed
- AWS CLI configured with credentials
- ZIP utility for packaging Lambda

## Project Structure

```
lambda-api-gateway/
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Input variables
├── outputs.tf               # Output values
├── api_gateway.tf          # API Gateway resources
├── lambda_function.tf      # Lambda resources
├── iam.tf                  # IAM roles and policies
├── zip_build.sh           # Build script for Lambda ZIP
├── src/
│   └── index.js           # Lambda function source
└── terraform.tfvars.example  # Variable values example
```

## Steps

### 1. Configure Variables

Copy and edit `terraform.tfvars`:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit with your values:

```hcl
environment = "production"
lambda_runtime = "nodejs20.x"
lambda_memory = 256
lambda_timeout = 30
api_stage = "v1"
enable_throttling = true
cors_enabled = true
```

### 2. Build Lambda Package

Run the build script:

```bash
chmod +x zip_build.sh
./zip_build.sh
```

This creates `lambda_function.zip` containing your function code.

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the output to ensure resources will be created as expected.

### 5. Apply Configuration

```bash
terraform apply tfplan
```

### 6. Verify Deployment

Check the outputs for the API endpoint URL:

```bash
terraform output
```

Test the API:

```bash
curl https://<api-id>.execute-api.<region>.amazonaws.com/v1/hello
```

Expected response:

```json
{"message": "Hello from Lambda!", "status": "success"}
```

## Verify

### Verify Lambda Function

```bash
aws lambda get-function --function-name <function-name>
```

### Verify API Gateway

```bash
aws apigatewayv2 get-api --api-id <api-id>
```

### Check CloudWatch Logs

```bash
aws logs describe-log-groups --log-group-prefix /aws/lambda/<function-name>
```

### Test with Different Paths

```bash
# Test root endpoint
curl https://<api-id>.execute-api.<region>.amazonaws.com/v1/

# Test health check
curl https://<api-id>.execute-api.<region>.amazonaws.com/v1/health

# Test with query params
curl "https://<api-id>.execute-api.<region>.amazonaws.com/v1/hello?name=Test"
```

## Rollback

### Destroy All Resources

```bash
terraform destroy
```

### Rollback to Previous Version

```bash
terraform apply -var="lambda_version=previous-tag"
```

### Delete Specific Resources Only

```bash
# Delete just the API Gateway
terraform destroy -target=aws_api_gateway_rest_api.api

# Delete just Lambda
terraform destroy -target=aws_lambda_function.lambda
```

## Common Errors

### "Error creating Lambda function: InvalidParameterValueException"

```
The runtime nodejs20.x is not supported.
```
**Fix:** Use a supported runtime. Check https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html

### "Error creating API Gateway: BadRequestException"

```
Invalid mapping expression specified
```
**Fix:** Verify the mapping template in `api_gateway.tf` uses correct parameter names.

### "Lambda function fails to execute: 502 Bad Gateway"

```
{"Message": "Internal server error"}
```
**Fix:** Check CloudWatch logs for the Lambda function. Common causes:
- Missing required environment variables
- Function timeout too short
- Incorrect handler path in configuration

### "Permission denied when invoking Lambda"

```
Access denied
```
**Fix:** Ensure API Gateway has permission to invoke Lambda:

```hcl
resource "aws_lambda_permission" "api" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
```

### "Throttling errors when calling API"

```
{"Message": "Too Many Requests"}
```
**Fix:** Adjust throttling settings in `api_gateway.tf`:

```hcl
resource "aws_api_gateway_method" "any" {
  # ...
  request_parameters {
    "method.request.header.X-Rate-Limit-Limit" = true
  }
}
```

## References

- AWS Lambda Documentation: https://docs.aws.amazon.com/lambda/
- API Gateway Documentation: https://docs.aws.amazon.com/apigateway/
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws
- Lambda Runtime Support: https://docs.aws.amazon.com/lambda/latest/dg/runtime-support-policy.html
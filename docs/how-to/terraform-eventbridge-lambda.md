# Terraform EventBridge with Lambda Triggers

## Purpose

This project demonstrates how to use AWS EventBridge to trigger AWS Lambda functions based on various AWS events. It provides a complete Infrastructure as Code setup using Terraform to deploy an event-driven architecture that reacts to AWS service events in real-time.

## When to use

- **Real-time event processing**: When you need to react to AWS events (EC2 state changes, S3 object operations, etc.) immediately
- **Audit and compliance**: Capture and process security-relevant events across your AWS infrastructure
- **Automation workflows**: Trigger automated responses to infrastructure changes without polling
- **Cross-service coordination**: Coordinate actions between different AWS services based on events
- **Notification systems**: Send alerts or notifications when specific events occur

## Prerequisites

- AWS account with appropriate permissions
- Terraform >= 1.0 installed
- AWS CLI configured with credentials
- jq installed for JSON processing
- Basic understanding of AWS EventBridge and Lambda

## Steps

### Step 1: Clone and Navigate to Project

```bash
cd terraform/eventbridge-lambda
```

### Step 2: Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter default region name (e.g., us-east-1)
# Enter output format (json)
```

Verify authentication:

```bash
aws sts get-caller-identity
```

### Step 3: Initialize Terraform

```bash
terraform init
```

This will download the required AWS provider and initialize the backend.

### Step 4: Create Environment Configuration

Edit the environment-specific tfvars file in `environments/` directory:

```bash
# For development
vi environments/dev.tfvars

# For production
vi environments/prod.tfvars
```

### Step 5: Plan the Deployment

```bash
# Plan for dev environment
terraform plan -var-file="environments/dev.tfvars" -out=tfplan

# Review the output to understand what will be created
```

### Step 6: Deploy the Infrastructure

```bash
# Apply the plan
terraform apply tfplan

# Or use the convenience script
cd ../../scripts/bash/terraform
./ter-019-deploy.sh --environment dev --region us-east-1 --apply
```

### Step 7: Verify Deployment

Check the created resources:

```bash
# List Lambda functions
aws lambda list-functions --query 'Functions[].FunctionName'

# List EventBridge rules
aws events list-rules --query 'Rules[].Name'

# Check CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/eventbridge"
```

### Step 8: Test the EventBridge Rule

Trigger a test event by creating an S3 object:

```bash
aws s3 cp test.txt s3://<bucket-name>/
```

Check Lambda logs:

```bash
aws logs tail /aws/lambda/eventbridge-processor-dev --follow
```

## Verify

After deployment, verify the following:

1. **Lambda Function**: Confirm it's created and has the correct configuration
   ```bash
   aws lambda get-function --function-name eventbridge-processor-dev
   ```

2. **EventBridge Rule**: Confirm the rule is active
   ```bash
   aws events describe-rule --name eventbridge-lambda-trigger-dev
   ```

3. **Permissions**: Confirm EventBridge can invoke Lambda
   ```bash
   aws lambda get-policy --function-name eventbridge-processor-dev
   ```

4. **Event Delivery**: Test by triggering an event and checking Lambda invocation
   ```bash
   aws lambda invoke --function-name eventbridge-processor-dev \
     --payload '{"test":"event"}' response.json
   cat response.json
   ```

## Rollback

To destroy the deployed resources:

```bash
# Using Terraform
terraform destroy -var-file="environments/dev.tfvars" -auto-approve

# Using the script
cd ../../scripts/bash/terraform
./ter-019-deploy.sh --environment dev --region us-east-1 --destroy
```

**Note**: The S3 bucket has `prevent_destroy` lifecycle protection. Remove this in `main.tf` before running destroy if you need to delete the bucket.

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Error: InvalidLambdaFunctionURI` | Lambda function ARN is incorrect | Verify the Lambda function exists and the ARN is correct |
| `Error: RuleAlreadyExists` | EventBridge rule already exists | Use a different environment or delete existing rule |
| `Access Denied` | Missing IAM permissions | Ensure your AWS credentials have Lambda, EventBridge, and IAM permissions |
| `Error creating S3 bucket: BucketAlreadyExists` | S3 bucket name is globally unique | The bucket name includes account ID, but may still conflict. Use a different naming scheme |
| `Error: InvalidEventPattern` | Event pattern JSON is malformed | Validate the event pattern JSON syntax |
| `aws: command not found` | AWS CLI not installed | Install AWS CLI: `curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"` |

## References

- [AWS EventBridge Documentation](https://docs.aws.amazon.com/eventbridge/)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EventBridge Event Patterns](https://docs.aws.amazon.com/eventbridge/latest/userguide/filtering-events.html)
- [AWS Lambda Permissions](https://docs.aws.amazon.com/lambda/latest/dg/lambda-permissions.html)
# AWS Secrets Manager Integration with Terraform

## Purpose

This project provides a complete walkthrough for integrating AWS Secrets Manager with Terraform to manage sensitive configuration data securely. It covers secret creation, Terraform provider configuration, dynamic secret retrieval, and best practices for secret rotation.

## When to Use

- When you need to manage database credentials, API keys, or other sensitive values in Terraform
- When building infrastructure that requires secure credential injection at runtime
- When implementing secret rotation strategies for compliance requirements
- When deploying applications that need to access secrets without hardcoding credentials
- When working in team environments where secrets should never be committed to version control

## Prerequisites

- AWS account with Secrets Manager and IAM permissions
- Terraform >= 1.0 installed
- AWS CLI configured with appropriate credentials
- Basic understanding of Terraform state management
- Understand of AWS IAM policies for Secrets Manager

## Steps

### Step 1: Install and Configure AWS CLI and Terraform

Install AWS CLI and Terraform on your workstation:

```bash
# Install AWS CLI (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y awscli

# Verify installation
aws --version
terraform --version

# Configure AWS credentials
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter default region name (e.g., us-east-1)
# Enter output format (json)
```

### Step 2: Create AWS Secrets Manager Secret

Create a secret in AWS Secrets Manager:

```bash
# Create a simple credential secret
aws secretsmanager create-secret \
  --name "my-database/credentials" \
  --secret-string '{"username":"dbadmin","password":"SecurePassword123!","engine":"postgres"}' \
  --region us-east-1

# Verify the secret was created
aws secretsmanager describe-secret \
  --secret-id "my-database/credentials" \
  --region us-east-1
```

### Step 3: Create IAM Policy for Secrets Manager Access

Create an IAM policy to allow Terraform to read secrets:

```bash
# Create policy document
cat > secrets-manager-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:123456789012:secret:my-database/*"
    }
  ]
}
EOF

# Create the policy
aws iam create-policy \
  --policy-name TerraformSecretsManagerAccess \
  --policy-document file://secrets-manager-policy.json

# Attach policy to IAM user/role
aws iam attach-user-policy \
  --policy-arn arn:aws:iam::123456789012:policy/TerraformSecretsManagerAccess \
  --user-name your-iam-user
```

### Step 4: Create Terraform Configuration

Create the main Terraform configuration file:

```hcl
# main.tf

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Data source to retrieve secret from Secrets Manager
data "aws_secretsmanager_secret_version" "db_credentials" {
  name = "my-database/credentials"
}

# Parse the secret JSON
locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
}

# Use the credentials in a resource (example: RDS instance)
resource "aws_db_instance" "example" {
  identifier           = "example-db"
  engine               = "postgres"
  engine_version       = "14.7"
  instance_class      = "db.t3.micro"
  allocated_storage  = 20
  storage_encrypted   = true

  name     = "exampledb"
  username = local.db_creds.username
  password = local.db_creds.password

  # Use secret ARN for deletion protection
  deletion_protection = true

  tags = {
    ManagedBy = "Terraform"
    Secret   = data.aws_secretsmanager_secret_version.db_credentials.arn
  }
}

# Output the secret ARN for reference
output "secret_arn" {
  value = data.aws_secretsmanager_secret_version.db_credentials.arn
}
```

### Step 5: Initialize and Apply Terraform

Initialize and apply the configuration:

```bash
# Initialize Terraform
terraform init

# Plan the changes
terraform plan -out=tfplan

# Apply the configuration
terraform apply tfplan

# View the outputs
terraform output
```

### Step 6: Implement Secret Rotation

Set up automatic secret rotation:

```bash
# Enable automatic rotation (requires Lambda function)
aws secretsmanager rotate-secret \
  --secret-id "my-database/credentials" \
  --rotation-lambda-arn arn:aws:lambda:us-east-1:123456789012:function:secrets-manager-rotation \
  --rotation-rules '{"AutomaticallyAfterDays": 30}' \
  --region us-east-1
```

### Step 7: Use Secrets in Kubernetes

For Kubernetes deployments, create an external secret:

```yaml
# kubernetes/external-secret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials-secret
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: db-credentials
    creationPolicy: Owner
  data:
    - remoteRef:
        key: my-database/credentials
        property: username
      secretKey: username
    - remoteRef:
        key: my-database/credentials
        property: password
        conversionStrategy: Exclude
      secretKey: password
```

### Step 8: Best Practices - Secret Injection at Runtime

Use secret injection rather than environment variables:

```hcl
# Use AWS Systems Manager Parameter Store for application config
data "aws_ssm_parameter" "app_config" {
  name = "/myapp/config"
  with_decryption = true
}

# Or use secrets as container environment variables (not recommended for passwords)
# Instead, mount as volumes or use sidecar pattern
```

## Verify

### Verify Secret Retrieval

```bash
# Check that Terraform successfully retrieved the secret
terraform state show data.aws_secretsmanager_secret_version.db_credentials

# Verify the secret exists in AWS
aws secretsmanager get-secret-value \
  --secret-id my-database/credentials \
  --region us-east-1
```

### Verify IAM Permissions

```bash
# Test access with AWS CLI
aws secretsmanager describe-secret \
  --secret-id my-database/credentials

# Check Terraform can access the secret
terraform plan 2>&1 | grep -i "secret"
```

## Rollback

### Remove Terraform Resources

```bash
# Destroy Terraform-managed resources
terraform destroy

# Confirm with "yes" when prompted
```

### Remove AWS Resources

```bash
# Delete the secret (use --force if needed)
aws secretsmanager delete-secret \
  --secret-id my-database/credentials \
  --force-delete-without-recovery \
  --region us-east-1

# Detach and delete IAM policy
aws iam detach-user-policy \
  --policy-arn arn:aws:iam::123456789012:policy/TerraformSecretsManagerAccess \
  --user-name your-iam-user

aws iam delete-policy \
  --policy-arn arn:aws:iam::123456789012:policy/TerraformSecretsManagerAccess
```

## Common Errors

| Error | Solution |
|-------|----------|
| `AccessDeniedException` | Verify IAM user/role has Secrets Manager read permissions |
| `Secret not found` | Check the secret name matches exactly, including the path prefix |
| `Invalid secret string` | Ensure secret is valid JSON for JSON secrets |
| `ThrottlingException` | Implement retry logic or request AWS limit increase |
| `InvalidNextToken` | Clear Terraform state and retry the operation |
| `-secret is marked for deletion` | Restore from AWS console or wait 7-30 days |

## References

- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [Terraform AWS Secrets Manager Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret)
- [AWS Secrets Manager Best Practices](https://aws.amazon.com/secrets-manager/faqs/)
- [External Secrets Operator](https://external-secrets.io/)
- [AWS IAM Policy Generator](https://aws.amazon.com/iam/)


## Additional Resources

### Example: Multiple Secrets

```hcl
# Retrieve multiple secrets
data "aws_secretsmanager_secret_version" "api_keys" {
  name = "myapp/api-keys"
}

data "aws_secretsmanager_secret_version" "db_creds" {
  name = "myapp/database"
}

locals {
  api_keys = jsondecode(data.aws_secretsmanager_secret_version.api_keys.secret_string)
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)
}
```

### Example: Secret Rotation Lambda

```python
import json
import boto3
import os

def lambda_handler(event, context):
    secret_name = os.environ['SECRET_NAME']
    
    # Get current secret
    client = boto3.client('secretsmanager')
    current = client.get_secret_value(SecretId=secret_name)
    current_secret = json.loads(current['SecretString'])
    
    # Generate new password
    import secrets
    import string
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*()"
    new_password = ''.join(secrets.choice(alphabet) for _ in range(32))
    
    # Create new secret
    new_secret = current_secret.copy()
    new_secret['password'] = new_password
    
    client.put_secret_value(
        SecretId=secret_name,
        SecretString=json.dumps(new_secret)
    )
    
    return {"statusCode": 200, "body": "Secret rotated"}
```
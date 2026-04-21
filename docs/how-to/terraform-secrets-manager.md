# Terraform AWS Secrets Manager Integration

## Purpose

This guide provides a comprehensive project walkthrough for integrating AWS Secrets Manager with Terraform infrastructure. It covers storing, retrieving, and managing sensitive credentials, API keys, and secrets as code using the official AWS provider for Terraform.

## When to use

- Deploying applications that require database credentials, API keys, or service tokens
- Implementing infrastructure-as-code with secrets stored outside version control
- Rotating credentials automatically without manual intervention
- Following security best practices for secrets management in AWS

## Prerequisites

- Terraform >= 1.0 installed
- AWS CLI configured with appropriate credentials
- AWS account with Secrets Manager access
- Appropriate IAM permissions for Secrets Manager operations
- Basic understanding of Terraform state management

## Steps

### Step 1: Create the Secrets Manager Structure

Create the directory structure:
```bash
mkdir -p terraform-secrets-manager/modules/secret
mkdir -p terraform-secrets-manager/modules/policy
mkdir -p terraform-secrets-manager/environments/dev
mkdir -p terraform-secrets-manager/environments/prod
```

### Step 2: Define the Secret Module

Create `modules/secret/main.tf`:
```hcl
resource "aws_secretsmanager_secret" "this" {
  name        = var.name
  description = var.description
  kms_key_id  = var.kms_key_id

  recovery_window_in_days = var.recovery_window_days

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.secret_string

  version_stages = var.version_stages
}
```

### Step 3: Create Variables

Create `modules/secret/variables.tf`:
```hcl
variable "name" {
  description = "Name of the secret"
  type        = string
}

variable "description" {
  description = "Description of the secret"
  type        = string
  default    = "Managed by Terraform"
}

variable "secret_string" {
  description = "JSON string of secret values"
  type        = string
  sensitive  = true
}

variable "kms_key_id" {
  description = "KMS key ARN for encryption"
  type        = string
  default    = null
}

variable "recovery_window_days" {
  description = "Recovery window in days"
  type        = number
  default    = 7
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default    = {}
}

variable "version_stages" {
  description = "Version stages to keep"
  type        = list(string)
  default    = ["AWSCURRENT"]
}
```

### Step 4: Create Outputs

Create `modules/secret/outputs.tf`:
```hcl
output "secret_id" {
  description = "ID of the secret"
  value       = aws_secretsmanager_secret.this.id
}

output "secret_arn" {
  description = "ARN of the secret"
  value       = aws_secretsmanager_secret.this.arn
}

output "version_id" {
  description = "Version ID of the secret"
  value       = aws_secretsmanager_secret_version.this.id
}
```

### Step 5: Create the Policy Module

Create `modules/policy/main.tf` for fine-grained access:
```hcl
data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.principal_arns
    }

    actions = var.allow_actions

    resources = var.secret_arns
  }
}

resource "aws_secretsmanager_secret_policy" "this" {
  count = var.attach_policy ? 1 : 0

  secret_arn = var.secret_arn
  policy    = data.aws_iam_policy_document.this.json
}
```

### Step 6: Create the Environment Configuration

Create `environments/dev/main.tf`:
```hcl
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
  region = var.aws_region
}

module "db_credentials" {
  source = "../../modules/secret"

  name           = "${var.project}-${var.environment}-db-credentials"
  description   = "Database credentials for ${var.environment}"
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_host
    port     = var.db_port
    database = var.db_name
  })
  
  tags = var.tags
}

module "api_keys" {
  source = "../../modules/secret"

  name           = "${var.project}-${var.environment}-api-keys"
  description   = "API keys for ${var.environment}"
  secret_string = jsonencode({
    api_key    = var.api_key
    api_secret = var.api_secret
  })
  
  tags = var.tags
}
```

### Step 7: Create Deployment Script

Create `scripts/deploy.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Terraform Secrets Manager deployment script
# Usage: ./deploy.sh <environment> <action>

ENVIRONMENT="${1:-dev}"
ACTION="${2:-apply}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check for required tools
check_requirements() {
  command -v terraform >/dev/null 2>&1 || { log_error "terraform not found"; exit 1; }
  command -v aws >/dev/null 2>&1 || { log_error "aws CLI not found"; exit 1; }
}

# Initialize Terraform
init_terraform() {
  log_info "Initializing Terraform for $ENVIRONMENT..."
  cd "environments/$ENVIRONMENT"
  terraform init -upgrade
}

# Plan changes
plan() {
  log_info "Planning changes for $ENVIRONMENT..."
  terraform plan -out=tfplan
}

# Apply changes
apply() {
  log_info "Applying changes for $ENVIRONMENT..."
  terraform apply tfplan
}

# Destroy environment
destroy() {
  log_warn "Destroying $ENVIRONMENT environment..."
  read -p "Are you sure? (yes/no): " confirm
  if [ "$confirm" = "yes" ]; then
    terraform destroy -auto-approve
  fi
}

# Main execution
main() {
  check_requirements
  init_terraform
  
  case "$ACTION" in
    plan)
      plan
      ;;
    apply)
      plan
      apply
      ;;
    destroy)
      destroy
      ;;
    *)
      log_error "Unknown action: $ACTION"
      exit 1
      ;;
  esac
}

main "$@"
```

### Step 8: Create the Walkthrough Document

Create `docs/how-to/terraform-secrets-manager.md`:
```markdown
# Terraform AWS Secrets Manager Integration

## Overview

This project demonstrates integrating AWS Secrets Manager with Terraform for secure secrets management in infrastructure-as-code.

## Prerequisites

1. Terraform >= 1.0 installed
2. AWS CLI configured
3. Appropriate IAM permissions

## Deployment

### Development Environment

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

### Retrieve Secrets in Applications

```hcl
data "aws_secretsmanager_secret_version" "creds" {
  arn = module.db_credentials.secret_arn
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)
}
```

## Verify

Check the secrets were created:
```bash
aws secretsmanager list-secrets --max-items 10
```

## Rollback

To destroy secrets:
```bash
cd environments/dev
terraform destroy
```

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| AccessDeniedException | Missing IAM permissions | Add secretsmanager:* actions to IAM policy |
| InvalidParameterException | Invalid secret string | Ensure valid JSON format |
| ResourceNotFoundException | Secret not in region | Verify region matches |
```

## Verify

Verify the implementation by checking the created resources:
```bash
aws secretsmanager list-secrets --region us-east-1 --max-items 10
```

Expected output shows secrets created:
- project-dev-db-credentials
- project-dev-api-keys

## Rollback

If deployment fails or needs to be reset:
```bash
cd environments/dev
terraform destroy -auto-approve
git checkout -- .
```

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `AccessDeniedException` | Missing IAM permissions | Add `secretsmanager:*` to IAM policy |
| `InvalidParameterException` | Invalid JSON secret | Validate JSON format before apply |
| `ResourceNotFoundException` | Region mismatch | Ensure AWS region matches |
| `SecretAlreadyExistsException` | Secret name in use | Use unique names or enable rotation |

## References

- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [Terraform AWS Provider Secrets Manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret)
- [AWS KMS Best Practices](https://docs.aws.amazon.com/kms/latest/developerguide/best-practices.html)
- [IAM Policy for Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_identity-based-policies.html)
# Terraform State Management Best Practices

## Purpose

This document covers best practices for managing Terraform state — the mechanism Terraform uses to map your configuration to the real-world resources it manages. Proper state management is critical for security, collaboration, and operational reliability.

## When to use

- Setting up a new Terraform project from scratch
- Migrating from local state to remote state
- Configuring state backends for team collaboration
- Implementing state locking to prevent concurrent modifications
- Setting up state encryption for sensitive environments
- Disaster recovery planning for state files

## Prerequisites

- Terraform v1.10+ installed
- Access to a state backend (S3, GCS, Azure Blob, etc.)
- For remote state: appropriate credentials and permissions
- For state encryption: KMS key (AWS) or equivalent
- Understanding of Terraform workspaces (optional)

## Steps

### 1. Choose a state backend

A state backend determines where Terraform stores its state. For production, always use a remote backend:

**AWS S3 with DynamoDB locking:**
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

**Google Cloud Storage:**
```hcl
terraform {
  backend "gcs" {
    bucket = "my-terraform-state"
    prefix = "prod/state"
  }
}
```

**Azure Blob Storage:**
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state"
    storage_account_name = "terraformstate001"
    container_name      = "tfstate"
    key                 = "prod/terraform.tfstate"
  }
}
```

### 2. Enable state encryption

Protect sensitive state data at rest:

**AWS S3 encryption:**
```hcl
terraform {
  backend "s3" {
    # Server-side encryption enabled
    encrypt = true
    # Use KMS key for additional control
    kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}
```

**Enable state encryption in provider:**
```hcl
provider "aws" {
  # Enable Terraform Native State Encryption
  skip_requesting_account_id = true
}
```

### 3. Configure state locking

Prevent concurrent `terraform apply` operations that could corrupt state:

**DynamoDB table for locking:**
```hcl
resource "aws_dynamodb_table" "terraform_lock" {
  name           = "terraform-state-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

**Verify locking is working:**
```bash
# Terminal 1
terraform apply  # Holds lock

# Terminal 2
terraform plan   # Blocks with message:
# Error: Error acquiring the state lock
# Could not lock Terraform state file
```

### 4. Use Terraform workspaces

Isolate environments while sharing configuration:

```bash
# Create workspace
terraform workspace new production

# List workspaces
terraform workspace list

# Select workspace
terraform workspace select production
```

**Workspace-aware backend:**
```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "${terraform.workspace}/terraform.tfstate"
  }
}
```

### 5. Implement state file security

**Never commit state files to version control:**
```bash
# .gitignore
*.tfstate
*.tfstate.*
.terraform/
```

**Encrypt state files locally (optional):**
```bash
# Using tfsec or similar tools
tfsec --state-encrypt .
```

### 6. State migration and recovery

**Import existing resources:**
```bash
terraform import aws_instance.example i-1234567890abcdef0
```

**Pull state from remote:**
```bash
terraform state pull > terraform.tfstate
```

**Push state to remote:**
```bash
terraform state push terraform.tfstate
```

### 7. State backup and recovery

**Enable versioning on S3:**
```hcl
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = "my-terraform-state"
  versioning_configuration {
    status = "Enabled"
  }
}
```

**Enable replication for disaster recovery:**
```hcl
resource "aws_s3_bucket_replication_configuration" "terraform_state" {
  # ... replication configuration
}
```

### 8. Use remote state data sources

Reference outputs from other configurations:

```hcl
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "my-terraform-state"
    key    = "network/terraform.tfstate"
    region = "us-east-1"
  }
}

# Use outputs
subnet_id = data.terraform_remote_state.network.outputs.subnet_id
```

## Verify

### Check state backend configuration:
```bash
terraform state pull  # Verify connectivity
```

### Verify state locking:
```bash
# Try to acquire lock
terraform apply

# In another terminal, verify lock status
aws dynamodb get-item --table-name terraform-state-lock \
  --key '{"LockID": {"S": "prod/terraform.tfstate"}}'
```

### List state history:
```bash
# S3 versioning history
aws s3api list-object-versions \
  --bucket my-terraform-state \
  --prefix prod/terraform.tfstate
```

## Rollback

### Restore previous state version:
```bash
# S3
aws s3api get-object --bucket my-terraform-state \
  --key prod/terraform.tfstate \
  --version-id <previous-version-id> \
  terraform.tfstate.backup

terraform state push terraform.tfstate.backup
```

### Recover from corrupted state:
```bash
# Import resources again
terraform import aws_instance.example i-1234567890abcdef0

# Or use state backup
terraform state push terraform.tfstate.backup
```

## Common errors

### "Error acquiring the state lock"

**Problem:** Another process is holding the state lock.

**Solution:** Wait for the other process to complete, or force unlock:
```bash
terraform force-unlock <lock-id>
```

### "Error loading state"

**Problem:** Cannot connect to the state backend.

**Solution:** Verify credentials and network connectivity:
```bash
aws sts get-caller-identity
terraform init
```

### "Dangling resources"

**Problem:** State drift where resources exist in cloud but not in state.

**Solution:** Refresh and import:
```bash
terraform refresh
terraform import <resource> <id>
```

### "Provider version mismatch"

**Problem:** State was created with different provider version.

**Solution:** Pin provider versions and upgrade carefully:
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

## References

- [Terraform State Documentation](https://developer.hashicorp.com/terraform/language/state)
- [S3 Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/s3)
- [State Locking](https://developer.hashicorp.com/terraform/language/state/locking)
- [Remote State Data Sources](https://developer.hashicorp.com/terraform/language/state/remote-state-data)
- [State Encryption](https://developer.hashicorp.com/terraform/language/state/sensitive-data)

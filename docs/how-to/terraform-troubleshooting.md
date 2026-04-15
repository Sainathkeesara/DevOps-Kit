# Terraform Troubleshooting Guide

## Purpose

This guide helps diagnose and resolve common issues encountered during Terraform plan and apply operations. It covers error messages, configuration problems, and practical debugging techniques.

## When to use

- `terraform plan` fails with errors
- `terraform apply` fails during resource creation
- State inconsistencies between Terraform and cloud resources
- Provider errors or version conflicts
- Authentication and credential issues with cloud providers

## Prerequisites

- Terraform v1.10+ installed
- AWS/GCP/Azure CLI configured
- Understanding of Terraform basics
- Access to cloud provider console (for verification)

## Steps

### 1. Terraform init issues

**Problem:** `terraform init` fails

**Diagnosis:**
```bash
# Check provider version
terraform version

# Show initialization details
terraform init -verbose

# Debug provider issues
TF_LOG=DEBUG terraform init 2>&1 | tee init.log
```

**Solutions:**

Provider mirror configuration:
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Use provider mirror
  provider_meta "aws" {
    module_name = "my_module"
  }
}
```

### 2. Authentication errors

**AWS authentication failures:**
```bash
# Verify credentials
aws sts get-caller-identity

# Set credentials explicitly
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

# Use profile
export AWS_PROFILE="production"
```

**Azure authentication:**
```bash
az login
az account show

# Set subscription
az account set --subscription "subscription-id"
```

**GCP authentication:**
```bash
gcloud auth application-default login
gcloud config list
```

### 3. Provider version conflicts

**Problem:** "Provider version mismatch" errors

**Solution - Pin provider versions:**
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.0.0"  # Exact version
    }
  }
}
```

**Upgrade providers safely:**
```bash
# Upgrade to latest allowed version
terraform init -upgrade

# Or upgrade specific provider
terraform init -upgrade -get-plugins=false
```

### 4. State locking issues

**Problem:** "Error acquiring the state lock"

**Solution:**
```bash
# Wait for other process to complete
# OR force unlock (use cautiously)
terraform force-unlock <lock-id>

# View current locks
aws dynamodb get-item \
  --table-name terraform-state-lock \
  --key '{"LockID": {"S": "prod/terraform.tfstate"}}'
```

### 5. Resource creation failures

**Problem:** `terraform apply` fails on resource creation

**Diagnosis - Read the error carefully:**
```bash
# Run with detailed logging
TF_LOG=ERROR terraform apply -verbose 2>&1 | tee apply.log

# Check resource-specific errors
terraform apply 2>&1 | grep -A 5 "Error:"
```

**Common solutions:**

**Resource already exists:**
```bash
# Import existing resource
terraform import aws_instance.example i-1234567890abcdef0
```

**Insufficient permissions:**
```bash
# Check IAM policy
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:user/terraform-user \
  --action-name ec2:DescribeInstances
```

**Quota exceeded:**
```bash
# Check AWS quotas
aws ec2 describe-account-details

# Request quota increase
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --desired-value 100
```

### 6. State drift issues

**Problem:** State doesn't match actual resources

**Diagnosis:**
```bash
# Show differences
terraform plan -out=tfplan

# Refresh state
terraform refresh

# Show current state
terraform show
```

**Solutions:**

**Import missing resources:**
```bash
terraform import aws_instance.web i-1234567890abcdef0
```

**Taint corrupted resources:**
```bash
terraform taint aws_instance.example
terraform apply
```

**Remove deleted resources from state:**
```bash
terraform state rm aws_instance.deleted
```

### 7. Plan/Apply differences

**Problem:** `terraform plan` shows changes but apply does something different

**Solution - Use saved plan:**
```bash
# Save plan to file
terraform plan -out=tfplan

# Review plan
terraform show tfplan

# Apply exactly what was planned
terraform apply tfplan
```

### 8. Dependency cycle errors

**Problem:** "Cycle" or "Circular dependency" errors

**Diagnosis:**
```bash
terraform graph | grep -E "depends|require"
```

**Solution - Refactor:**
```hcl
# Use explicit dependencies
resource "aws_instance" "example" {
  # Explicit dependency
  depends_on = [aws_security_group.example]
}
```

### 9. Timeout errors

**Problem:** Operations timeout (especially for cloud resources)

**Solution:**
```hcl
resource "aws_instance" "example" {
  # Increase timeouts
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}
```

### 10. Sensitive data in state

**Problem:** Secrets visible in state

**Solution - Mark sensitive values:**
```hcl
variable "api_key" {
  type        = string
  sensitive   = true
}

output "db_password" {
  value     = aws_db_instance.example.password
  sensitive = true
}
```

## Verify

### Check resource status:
```bash
terraform show

# Query specific resource
terraform state show aws_instance.example
```

### Verify cloud resources:
```bash
# AWS
aws ec2 describe-instances --instance-ids i-1234567890abcdef0

# Azure
az vm show --resource-group mygroup --name myvm

# GCP
gcloud compute instances describe myinstance --zone us-central1-a
```

### Check plan output:
```bash
# Detailed plan
terraform plan -detailed-exitcode

# JSON output for parsing
terraform plan -json > plan.json
```

## Rollback

### Destroy failed resources:
```bash
terraform destroy -target=<resource> -auto-approve
```

### Restore from state backup:
```bash
# Pull state
terraform state pull > backup.tfstate

# Restore
terraform state push backup.tfstate
```

### Use target to recreate specific resources:
```bash
terraform apply -target=aws_instance.example -auto-approve
```

## Common errors

### "InvalidReferenceException: Cannot update"

**Problem:** Trying to update immutable fields.

**Solution:** Recreate the resource:
```bash
terraform taint aws_instance.example
terraform apply
```

### "AccessDenied"

**Problem:** Missing IAM permissions.

**Solution:** Add required permissions to IAM role/user.

### "ResourceNotFound"

**Problem:** Resource was deleted outside Terraform.

**Solution:** Remove from state and re-import:
```bash
terraform state rm aws_instance.example
terraform import aws_instance.example i-1234567890abcdef0
```

### "Timeout while waiting for resource"

**Problem:** Resource took too long to create.

**Solution:** Increase timeout or check service status.

### "Error validating VPC"

**Problem:** VPC or subnet not found.

**Solution:** Verify VPC exists:
```bash
aws ec2 describe-vpcs
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-12345678"
```

## References

- [Terraform Troubleshooting Docs](https://developer.hashicorp.com/terraform/tutorials/state/state-troubleshooting)
- [AWS Provider Troubleshooting](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/troubleshooting)
- [Terraform Debugging](https://developer.hashicorp.com/terraform/internals/debugging)

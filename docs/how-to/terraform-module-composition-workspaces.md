# Terraform Module Composition and Workspaces Guide

## Purpose

This guide explains how to structure Terraform projects using module composition and workspace isolation to manage multiple environments (dev, staging, prod) with shared infrastructure code.

## When to use

- Managing multiple environments with consistent infrastructure
- Creating reusable Terraform modules
- Implementing workspace-based environment isolation
- Following infrastructure-as-code best practices

## Prerequisites

- Terraform >= 1.5.0 installed
- AWS CLI configured with credentials
- Basic knowledge of Terraform syntax
- Understanding of AWS networking concepts

## Steps

### Step 1: Create Project Structure

Create the following directory structure:

```bash
mkdir -p terraform-project/modules/{compute,network,storage}
cd terraform-project
```

### Step 2: Configure Root Module

Create `main.tf` with module composition:

```hcl
terraform {
  required_version = ">= 1.5.0"
  
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

module "vpc" {
  source = "./modules/network"
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

module "compute" {
  source         = "./modules/compute"
  environment    = var.environment
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  instance_type  = var.instance_type
}
```

### Step 3: Define Variables

Create `variables.tf` with validation:

```hcl
variable "environment" {
  type        = string
  description = "Environment name"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod"
  }
}
```

### Step 4: Create Reusable Modules

Create network module in `modules/network/main.tf`:

```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  # ... configuration
}

resource "aws_subnet" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  # ... configuration
}
```

### Step 5: Configure Workspaces

Initialize and create workspaces:

```bash
terraform init
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
```

### Step 6: Environment-Specific Configuration

Use workspace-specific variable files:

```bash
# dev.tfvars
environment = "dev"
instance_type = "t3.micro"

# prod.tfvars  
environment = "prod"
instance_type = "t3.large"
```

### Step 7: Plan and Apply

```bash
terraform workspace select dev
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

### Step 8: Implement State Isolation

Configure backend with workspace isolation:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "env:/${terraform.workspace}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}
```

## Verify

```bash
# Check current workspace
terraform workspace show

# List all workspaces
terraform workspace list

# Show outputs
terraform output

# Verify resources in AWS console or CLI
aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=${terraform.workspace}"
```

## Rollback

```bash
# Destroy current workspace resources
terraform destroy -var-file=dev.tfvars

# Switch to previous state
terraform workspace select other-workspace

# Alternative: use state mv for recovery
terraform state mv aws_instance.old aws_instance.new
```

## Common errors

### Error: "Error acquiring the state lock"

**Cause**: Another Terraform process is running or previous run failed to release lock

**Solution**:
```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### Error: "Provider configuration not present"

**Cause**: Module missing provider configuration

**Solution**: Pass providers to modules:
```hcl
module "vpc" {
  source   = "./modules/network"
  providers = { aws = aws }
}
```

### Error: "Cycle" when evaluating variable

**Cause**: Circular dependency in module outputs

**Solution**: Restructure to use outputs instead of direct references

### Error: "Workspace does not exist"

**Cause**: Workspace not created

**Solution**:
```bash
terraform workspace new <name>
terraform workspace select <name>
```

## References

- [Terraform Workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces)
- [Module Composition](https://developer.hashicorp.com/terraform/language/modules/develop/composition)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

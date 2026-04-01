# Terraform Multi-Environment Infrastructure with GitOps Workflow

## Purpose

Deploy a production-grade multi-environment infrastructure on AWS using Terraform with a GitOps workflow. This project covers three environments (dev, staging, production) with isolated state backends, workspace-based configuration, and a structured promotion pipeline from dev → staging → production.

## When to use

- Building infrastructure that requires separate environments for development, staging, and production
- Implementing GitOps principles where infrastructure changes flow through version-controlled pipelines
- Managing infrastructure as code with proper separation of concerns and environment isolation
- Requiring audit trails and approval workflows for production infrastructure changes
- Using Terraform workspaces for environment-specific configuration management

## Prerequisites

- AWS account with appropriate permissions (IAM user or role with admin-level access)
- Terraform >= 1.6.0 installed locally
- AWS CLI configured with credentials
- Git repository initialized for the infrastructure code
- S3 bucket for Terraform state backend (create manually or use the script)
- DynamoDB table for state locking (create manually or use the script)

## Steps

### Step 1: Create S3 bucket and DynamoDB table for state management

The script `multi-env-setup.sh` creates the required backend resources:

```bash
cd scripts/bash/terraform_toolkit/multi-env
./multi-env-setup.sh --action init-backend
```

This creates:
- S3 bucket: `terraform-state-<account-id>-multi-env`
- DynamoDB table: `terraform-state-lock` for state locking

### Step 2: Clone and configure the repository

```bash
git clone <your-repo> terraform-multi-env
cd terraform-multi-env
```

### Step 3: Configure environment-specific variables

Each environment has its own `terraform.tfvars` file:

```bash
# Edit development environment variables
vim environments/dev/terraform.tfvars

# Edit staging environment variables  
vim environments/staging/terraform.tfvars

# Edit production environment variables
vim environments/prod/terraform.tfvars
```

Required variables per environment:
- `environment` = "dev" | "staging" | "prod"
- `aws_region` = "us-east-1" (or your preferred region)
- `vpc_cidr` = environment-specific CIDR block
- `instance_type` = environment-specific instance sizing
- `environment_tags` = environment-specific tags

### Step 4: Initialize and plan development environment

```bash
cd environments/dev
terraform init -backend-config="key=dev/terraform.tfstate"
terraform plan -out=tfplan
```

### Step 5: Apply development environment

```bash
terraform apply tfplan
```

After apply completes, note the outputs:
- VPC ID
- Subnet IDs
- Instance IPs
- Load balancer DNS

### Step 6: Promote to staging environment

Once development is verified, promote to staging:

```bash
cd ../staging
terraform init -backend-config="key=staging/terraform.tfstate"
terraform plan -var-file="terraform.tfvars" -out=tfplan
terraform apply tfplan
```

### Step 7: Production deployment with approval

Production requires manual approval:

```bash
cd ../prod
terraform init -backend-config="key=prod/terraform.tfstate"
terraform plan -var-file="terraform.tfvars" -out=tfplan
```

Before applying, review the plan output carefully. Production changes should be reviewed by at least one additional team member.

### Step 8: Configure GitOps workflow

Set up the GitOps pipeline using Atlantis or similar tool:

```yaml
# atlantis.yaml in repository root
version: 3
projects:
  - dir: environments/dev
    workflow: default
  - dir: environments/staging
    workflow: default  
  - dir: environments/prod
    workflow: default
workflows:
  default:
    plan:
      steps:
        - init
        - plan
    apply:
      steps:
        - apply
```

## Verify

### Verify development environment resources

```bash
# List all resources in dev
cd environments/dev
terraform state list

# Check VPC
aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=dev" --query "Vpcs[].VpcId"

# Check instances
aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev" --query "Reservations[].Instances[].InstanceId"

# Verify networking
aws ec2 describe-subnets --filters "Name=tag:Environment,Values=dev" --query "Subnets[].SubnetId"
```

### Verify state backend

```bash
# Check S3 bucket has state files
aws s3 ls s3://terraform-state-<account-id>-multi-env/

# Check DynamoDB lock table
aws dynamodb scan --table-name terraform-state-lock --query "Items"
```

### Verify GitOps integration

```bash
# Test Atlantis plan webhook
curl -X POST https://your-atlantis-url/events \
  -H "Content-Type: application/json" \
  -d '{"action":"opened","pull_request":{"number":1}}'
```

## Rollback

### Rollback to previous state

```bash
# Development environment
cd environments/dev
terraform apply -var-file="terraform.tfvars" -auto-approve

# Or restore from state file backup
terraform state pull > backup.tfstate
```

### Destroy environment (use with caution)

```bash
cd environments/dev
terraform destroy -var-file="terraform.tfvars"
```

### Clean up backend resources (after all environments destroyed)

```bash
cd scripts/bash/terraform_toolkit/multi-env
./multi-env-setup.sh --action destroy-backend
```

## Common errors

### Error: "Error acquiring the state lock"

**Symptom:** Terraform fails to acquire state lock for concurrent operations.

**Solution:** 
- Check DynamoDB table exists and has proper IAM permissions
- Force unlock if stuck: `terraform force-unlock <lock-id>`
- Ensure only one Terraform process runs at a time per environment

### Error: "S3 bucket does not exist"

**Symptom:** Backend initialization fails with bucket not found.

**Solution:**
```bash
aws s3 mb s3://terraform-state-<account-id>-multi-env --region <region>
```

### Error: "Invalid Terraform version"

**Symptom:** Backend configuration requires newer Terraform version.

**Solution:** Upgrade Terraform:
```bash
terraform version
wget -q https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### Error: "Circular dependency detected"

**Symptom:** Terraform fails to parse configuration with circular references.

**Solution:** Review module dependencies and ensure correct `depends_on` declarations. Break circular references by extracting common logic into separate modules.

### Error: "Provider version mismatch"

**Symptom:** AWS provider version incompatible with configuration.

**Solution:** Pin provider version in `versions.tf`:
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

### Error: "IAM permissions denied"

**Symptom:** Terraform cannot create or modify resources due to insufficient permissions.

**Solution:** Ensure IAM user/role has required permissions. Attach `AdministratorAccess` or minimum required policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*", 
        "iam:*", 
        "s3:*", 
        "dynamodb:*",
        "vpc:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## References

- [Terraform Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/configuration) (2026-01-15)
- [Terraform Workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces) (2026-01-15)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) (2026-02-01)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html) (2026-01-15)
- [Atlantis GitOps Workflow](https://www.runatlantis.io/) (2026-02-01)
- [Terraform State Management](https://developer.hashicorp.com/terraform/language/state) (2026-01-15)
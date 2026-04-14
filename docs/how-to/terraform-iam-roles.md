# Terraform IAM Roles with Policy Modules

## Purpose

Create reusable IAM roles and policy modules using Terraform that follow security best practices. This project demonstrates how to define IAM roles with least-privilege policies, condition-based access, and modular policy attachments that can be consumed across multiple AWS accounts.

## When to use

- Creating standardized IAM roles for application workloads
- Implementing least-privilege access for AWS services and resources
- Building reusable policy modules that can be shared across teams
- Setting up cross-account access with proper trust boundaries
- Meeting compliance requirements with auditable IAM configurations

## Prerequisites

- Terraform v1.10+ installed
- AWS CLI configured with appropriate credentials
- Access to AWS IAM service
- For cross-account scenarios: AWS Organization or proper trust relationships

## Steps

### 1. Create the policy module structure

Create a modular policy definition that can be attached to roles:

```hcl
# modules/iam-policy/main.tf
resource "aws_iam_policy" "this" {
  name        = var.policy_name
  description = var.description
  policy      = jsonencode(var.policy)
  tags        = var.tags
}
```

### 2. Define the role module

Create the IAM role with configurable trust relationships:

```hcl
# modules/iam-role/main.tf
resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = var.principal_type
      identifiers = var.principal_identifiers
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = var.allowed_accounts
    }
  }
}
```

### 3. Implement the project structure

Create the main project that combines roles and policies:

```hcl
# main.tf
module "app_role" {
  source = "./modules/iam-role"
  
  role_name             = "application-role"
  principal_type       = "Service"
  principal_identifiers = ["ec2.amazonaws.com", "lambda.amazonaws.com"]
  allowed_accounts      = [data.aws_caller_identity.current.account_id]
}

module "app_policy" {
  source = "./modules/iam-policy"
  
  policy_name = "app-s3-access"
  description = "S3 access policy for application role"
  policy = {
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.app_bucket}",
          "arn:aws:s3:::${var.app_bucket}/*"
        ]
      }
    ]
  }
}
```

### 4. Configure variables

Define input variables for flexibility:

```hcl
# variables.tf
variable "app_bucket" {
  description = "S3 bucket name for application access"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}
```

### 5. Add outputs for consumption

Expose role ARNs for other modules to use:

```hcl
# outputs.tf
output "role_arn" {
  description = "ARN of the created IAM role"
  value       = module.app_role.role_arn
}
```

### 6. Add policy attachment

Attach the policy to the role:

```hcl
# modules/iam-role-attachment/main.tf
resource "aws_iam_role_policy_attachment" "this" {
  role       = var.role_name
  policy_arn = var.policy_arn
}
```

### 7. Configure security features

Add MFA requirements and session policies:

```hcl
# modules/iam-mfa-policy/main.tf
data "aws_iam_policy_document" "mfa_required" {
  statement {
    effect = "Deny"
    not_actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ResyncMFADevice"
    ]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}
```

### 8. Set up cost allocation tags

Add tagging for cost tracking:

```hcl
# tags.tf
locals {
  common_tags = {
    Environment = var.environment
    Project     = "platform"
    ManagedBy   = "terraform"
    CostCenter = "engineering"
  }
}
```

### 9. Configure logging

Enable CloudTrail for IAM operations:

```hcl
# cloudtrail.tf
resource "aws_cloudtrail" "iam_events" {
  name           = "iam-events-trail"
  s3_bucket_name = var.cloudtrail_bucket
  include_cloudtrail_service_events = true
  is_multi_region_trail = true
  enable_log_file_validation = true
  
  event_selector {
    read_write_type           = "All"
    include_management_events = true
    data_resource {
      type   = "AWS::IAM::User"
      values = ["arn:aws:iam::*:user/*"]
    }
  }
}
```

### 10. Verify the deployment

Run terraform commands to verify:

```bash
terraform init
terraform validate
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

## Verify

### Check role creation

```bash
aws iam get-role --role-name application-role
```

### Verify policy attachment

```bash
aws iam list-attached-role-policies --role-name application-role
```

### Test assume role

```bash
aws sts assume-role --role-arn arn:aws:iam::ACCOUNT:role/application-role --role-session-name test
```

### Check CloudTrail events

```bash
aws cloudtrail lookup-events --lookup-attributes attribute-key=EventSource,attribute-value=iam.amazonaws.com
```

## Rollback

### Destroy resources

```bash
terraform destroy -var-file="dev.tfvars"
```

### Manual cleanup

If Terraform state is lost, manually remove:

```bash
aws iam delete-role-policy --role-name application-role --policy-name app-s3-access
aws iam delete-role --role-name application-role
aws iam delete-policy --policy-name arn:aws:iam::ACCOUNT:policy/app-s3-access
```

## Common errors

### "Invalid principal in trust policy"

**Problem:** Principal type or identifier is incorrect.

**Solution:** Ensure the service principal uses the correct format (e.g., `ec2.amazonaws.com` for EC2, `lambda.amazonaws.com` for Lambda).

### "Policy has invalid principal"

**Problem:** IAM policy references a principal that doesn't exist or has a typo.

**Solution:** Verify the principal ARN or account ID is correct. Use `aws sts get-caller-identity` to confirm your account ID.

### "Malformed policy document"

**Problem:** JSON policy syntax error.

**Solution:** Use `aws iam validate-policy` to check for JSON syntax errors. Ensure proper escaping of special characters.

### "Role name already exists"

**Problem:** Role with the same name already exists in the account.

**Solution:** Use a unique naming convention with environment prefixes or use `terraform state mv` if the role was created outside Terraform.

### "Access denied" during plan

**Problem:** Insufficient permissions to read IAM resources.

**Solution:** Ensure your IAM user/role has `iam:*` permissions or at minimum `iam:Get*`, `iam:List*`, and `iam:SimulatePrincipalPolicy`.

## References

- [AWS IAM Terraform Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
- [IAM Policy Design](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform IAM Modules](https://github.com/terraform-aws-modules/terraform-aws-iam)
- [AWS Service Principal List](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_aws-services-that-work-with-iam.html)

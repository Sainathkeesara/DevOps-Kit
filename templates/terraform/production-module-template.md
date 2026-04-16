# Production Terraform Module Template

## Purpose

This template provides a production-ready, reusable Terraform module structure with built-in security guardrails. It establishes consistent patterns for module development across an organization, ensuring all infrastructure code follows security best practices by default.

## When to use

Use this template when:
- Creating a new Terraform module for infrastructure provisioning
- Standardizing module structure across multiple teams
- Building modules that will be published internally or publicly
- Requiring security guardrails (input validation, output sanitization) in infrastructure code

## Prerequisites

- Terraform >= 1.0.0 installed
- `terraform validate` available
- Access to provider credentials (AWS, Azure, GCP, etc.)
- tfsec or checkov for security scanning (optional but recommended)

## Steps

### 1. Module Structure

Create the following directory structure:

```
my-module/
├── .gitignore
├── .terraform-docs.yml
├── CHANGELOG.md
├── LICENSE
├── Makefile
├── README.md
├── examples/
│   ├── simple/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── complete/
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── test/
│   ├── go.mod
│   └── go.sum
├── main.tf
├── outputs.tf
├── providers.tf
├── variables.tf
├── versions.tf
└── Makefile
```

### 2. versions.tf — Provider Version Constraints

```hcl
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### 3. variables.tf — Input Validation

```hcl
variable "name" {
  description = "Name of the resource"
  type        = string
  nullable    = false

  validation {
    condition     = length(var.name) <= 64 && length(var.name) >= 3
    error_message = "Name must be between 3 and 64 characters."
  }

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name))
    error_message = "Name must start with lowercase letter, contain only lowercase letters, numbers, and hyphens, and end with lowercase letter or number."
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "enable_encryption" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
  nullable    = false
}
```

### 4. main.tf — Resource Creation with Guardrails

```hcl
locals {
  # Sanitized tags with required metadata
  common_tags = merge(
    var.tags,
    {
      "ManagedBy"   = "Terraform"
      "ModuleName"  = var.name
      "Environment" = var.environment
    }
  )
}

# Encryption guardrail
resource "aws_kms_key" "this" {
  count                = var.enable_encryption ? 1 : 0
  description          = "KMS key for ${var.name}"
  enable_key_rotation  = true
  deletion_window_days = 7

  tags = local.common_tags
}

# Secure resource creation
resource "aws_s3_bucket" "this" {
  bucket = var.name

  # Encryption guardrail
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.enable_encryption ? aws_kms_key.this[0].arn : null
        sse_algorithm     = var.enable_encryption ? "aws:kms" : "AES256"
      }
    }
  }

  # Versioning guardrail
  versioning {
    enabled = true
  }

  # Lifecycle guardrails
  lifecycle_rule {
    enabled = true

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }

    expiration {
      days = 365
    }
  }

  tags = local.common_tags
}
```

### 5. outputs.tf — Output Sanitization

```hcl
output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.this.id
  sensitive   = false
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.this.arn
  sensitive   = false
}

output "kms_key_arn" {
  description = "ARN of the KMS key (if encryption enabled)"
  value       = var.enable_encryption ? aws_kms_key.this[0].arn : null
  sensitive   = true
}
```

### 6. examples/simple/main.tf — Usage Example

```hcl
module "secure_bucket" {
  source = "../"

  name            = "my-secure-bucket"
  environment     = "production"
  enable_encryption = true

  tags = {
    Team = "Platform"
    CostCenter = "Engineering"
  }
}
```

### 7. Makefile — Build and Test

```makefile
.PHONY: init validate test lint clean

init:
	terraform init

validate:
	terraform validate

lint:
	@echo "Running tfsec..."
	tfsec . --soft-fail || true
	@echo "Running checkov..."
	checkov -d . --skip-check CKV_AWS_123 || true

test:
	cd test && go test -v ./...

clean:
	rm -rf .terraform
	rm -f .terraform.lock.hcl
```

## Verify

1. Run `terraform init` and `terraform validate` — both should pass
2. Run `make lint` — review any security warnings
3. Apply the example — verify resources are created with correct encryption
4. Run `terraform destroy` to clean up

## Rollback

To rollback:
```bash
terraform destroy
# Delete the module directory
rm -rf /path/to/module
```

## Common errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Provider version constraint error` | Incompatible provider version | Update `versions.tf` with correct version constraints |
| `Name validation failed` | Invalid resource name | Ensure name follows naming conventions (lowercase, hyphens) |
| `KMS key not found` | Encryption enabled but key not created | Check `count` and `enable_encryption` variable |
| `Output sensitive` | Attempting to output sensitive value | Mark sensitive outputs with `sensitive = true` |

## References

- [Terraform Module Registry](https://registry.terraform.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS Security Best Practices](https://docs.aws.amazon.com/whitepapers/latest/aws-security-best-practices/)
- [tfsec Documentation](https://aquasecurity.github.io/tfsec/)
- [checkov Documentation](https://www.checkov.io/)

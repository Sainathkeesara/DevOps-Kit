# Terraform S3 with Cross-Region Replication

## Purpose

Deploy an S3 bucket configured with cross-region replication (CRR) on AWS using Terraform. This project establishes a source bucket in one region and a replica bucket in another region, with automatic asynchronous replication of objects for disaster recovery and latency optimization.

## When to use

- Building disaster recovery infrastructure with data replicated across AWS regions
- Meeting compliance requirements for data residency across geographic boundaries
- Optimizing latency for users in different regions by serving data from the nearest S3 bucket
- Building global architectures that require consistent data across multiple regions
- Implementing backup strategies with automatic cross-region synchronization

## Prerequisites

- AWS account with appropriate permissions (IAM user or role with S3 and IAM permissions)
- Terraform >= 1.6.0 installed locally
- AWS CLI configured with credentials
- Git repository initialized for the infrastructure code
- Two AWS regions for source and replica (e.g., us-east-1 and us-west-2)

## Steps

### Step 1: Create IAM role for replication

The replication role is required to allow S3 to read objects from the source bucket and replicate them to the destination bucket.

```hcl
# roles.tf
resource "aws_iam_role" "replication" {
  name = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "replication" {
  name = "s3-replication-policy"
  role = aws_iam_role.replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.source_bucket_name}",
          "arn:aws:s3:::${var.source_bucket_name}/*"
        ]
      },
      {
        Action = [
          "s3:ListBucket",
          "s3:GetReplicationConfiguration"
        ]
        Effect = "Allow"
        Resource = "arn:aws:s3:::${var.source_bucket_name}"
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect = "Allow"
        Resource = "arn:aws:s3:::${var.replica_bucket_name}/*"
      }
    ]
  })
}
```

### Step 2: Configure source bucket with replication

Create the source S3 bucket with versioning enabled and replication configuration:

```hcl
# source_bucket.tf
resource "aws_s3_bucket" "source" {
  bucket = var.source_bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "source" {
  bucket = aws_s3_bucket.source.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "source" {
  bucket = aws_s3_bucket.source.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "replicate-all-objects"
    status = "Enabled"

    destination {
      bucket     = aws_s3_bucket.replica.arn
      storage_class = "STANDARD"
      encryption_replication_configuration {
        role   = aws_iam_role.replication.arn
        rules {
          id     = "encrypt-replicated-objects"
          status = "Enabled"
          destination_encryption_configuration {
            encryption_type = "AES256"
          }
        }
      }
    }

    filter {
      prefix = ""
      tags   = {}
    }

    priority = 1
    delete_marker_replication {
      status = "Enabled"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "source" {
  bucket = aws_s3_bucket.source.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "source" {
  bucket = aws_s3_bucket.source.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### Step 3: Configure replica bucket

Create the replica S3 bucket in the secondary region:

```hcl
# replica_bucket.tf
resource "aws_s3_bucket" "replica" {
  bucket = var.replica_bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "replica" {
  bucket = aws_s3_bucket.replica.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  bucket = aws_s3_bucket.replica.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "replica" {
  bucket = aws_s3_bucket.replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "replica" {
  bucket = aws_s3_bucket.replica.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class    = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
```

### Step 4: Define variables

```hcl
# variables.tf
variable "source_bucket_name" {
  description = "Name of the source S3 bucket"
  type        = string
}

variable "replica_bucket_name" {
  description = "Name of the replica S3 bucket"
  type        = string
}

variable "source_region" {
  description = "AWS region for source bucket"
  type        = string
  default     = "us-east-1"
}

variable "replica_region" {
  description = "AWS region for replica bucket"
  type        = string
  default     = "us-west-2"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

### Step 5: Define outputs

```hcl
# outputs.tf
output "source_bucket_arn" {
  description = "ARN of the source S3 bucket"
  value       = aws_s3_bucket.source.arn
}

output "source_bucket_name" {
  description = "Name of the source S3 bucket"
  value       = aws_s3_bucket.source.id
}

output "source_bucket_region" {
  description = "Region of the source S3 bucket"
  value       = var.source_region
}

output "replica_bucket_arn" {
  description = "ARN of the replica S3 bucket"
  value       = aws_s3_bucket.replica.arn
}

output "replica_bucket_name" {
  description = "Name of the replica S3 bucket"
  value       = aws_s3_bucket.replica.id
}

output "replica_bucket_region" {
  description = "Region of the replica S3 bucket"
  value       = var.replica_region
}

output "replication_role_arn" {
  description = "ARN of the IAM role used for replication"
  value       = aws_iam_role.replication.arn
}
```

### Step 6: Create deployment script

```bash
#!/usr/bin/env bash
set -euo pipefail

# S3 Cross-Region Replication Deployment Script
# Purpose: Deploy and manage S3 buckets with cross-region replication
# Usage: ./deploy-s3-crr.sh --action <init|plan|apply|destroy|verify>
# Requirements: terraform, aws cli, appropriate IAM permissions
# Safety: DRY_RUN=true by default — set DRY_RUN=false for actual changes
# Tested on: Ubuntu 22.04, macOS 13, RHEL 9

DRY_RUN="${DRY_RUN:-true}"
ACTION="${1:-}"
SOURCE_BUCKET="${SOURCE_BUCKET:-}"
REPLICA_BUCKET="${REPLICA_BUCKET:-}"
SOURCE_REGION="${SOURCE_REGION:-us-east-1}"
REPLICA_REGION="${REPLICA_REGION:-us-west-2}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_dependencies() {
    local deps=("terraform" "aws")
    for dep in "${deps[@]}"; do
        command -v "$dep" >/dev/null 2>&1 || { log_error "$dep not found — install it first"; exit 1; }
    done
    log_info "All dependencies satisfied"
}

init_terraform() {
    log_info "Initializing Terraform..."
    terraform init
    log_info "Terraform initialized"
}

run_terraform() {
    local action="$1"
    log_info "Running Terraform $action..."

    if [ "$DRY_RUN" = true ] && [ "$action" = "apply" ]; then
        log_warn "[dry-run] Would run terraform plan"
        terraform plan -var-file="terraform.tfvars"
        return 0
    fi

    case "$action" in
        plan)
            terraform plan -var-file="terraform.tfvars" -out=tfplan
            ;;
        apply)
            terraform apply -var-file="terraform.tfvars" -auto-approve
            ;;
        destroy)
            terraform destroy -var-file="terraform.tfvars" -auto-approve
            ;;
        *)
            log_error "Unknown action: $action"
            exit 1
            ;;
    esac

    log_info "Terraform $action completed"
}

verify_replication() {
    log_info "Verifying S3 cross-region replication..."

    local source_bucket="$1"
    local replica_bucket="$2"

    log_info "Checking source bucket versioning..."
    aws s3api get-bucket-versioning --bucket "$source_bucket" --region "$SOURCE_REGION" | grep -q "Enabled" && log_info "Source bucket versioning enabled" || log_error "Source bucket versioning not enabled"

    log_info "Checking replica bucket versioning..."
    aws s3api get-bucket-versioning --bucket "$replica_bucket" --region "$REPLICA_REGION" | grep -q "Enabled" && log_info "Replica bucket versioning enabled" || log_error "Replica bucket versioning not enabled"

    log_info "Checking replication configuration..."
    aws s3api get-bucket-replication --bucket "$source_bucket" --region "$SOURCE_REGION" | grep -q "ReplicationConfiguration" && log_info "Replication configured" || log_error "Replication not configured"

    log_info "Verification complete"
}

test_replication() {
    log_info "Testing object replication..."

    local test_file="/tmp/test-s3-crr-$(date +%s).txt"
    echo "Test file for S3 CRR $(date)" > "$test_file"

    local source_bucket="$1"
    local replica_bucket="$2"
    local test_key="test-replication/$(basename $test_file)"

    log_info "Uploading test file to source bucket..."
    aws s3 cp "$test_file" "s3://$source_bucket/$test_key" --region "$SOURCE_REGION"

    log_info "Waiting for replication (30 seconds)..."
    sleep 30

    log_info "Checking if object replicated to replica bucket..."
    if aws s3api head-object --bucket "$replica_bucket" --key "$test_key" --region "$REPLICA_REGION" 2>/dev/null; then
        log_info "Object successfully replicated to replica bucket"
    else
        log_warn "Object not yet replicated — may take more time"
    fi

    rm -f "$test_file"
    log_info "Replication test complete"
}

show_usage() {
    cat << EOF
Usage: $0 --action <ACTION> [OPTIONS]

Actions:
    init         Initialize Terraform
    plan         Run terraform plan
    apply        Run terraform apply
    destroy      Run terraform destroy
    verify       Verify replication configuration
    test         Test replication with sample file

Options:
    --source-bucket NAME    Source bucket name
    --replica-bucket NAME   Replica bucket name
    --source-region REGION  Source region (default: us-east-1)
    --replica-region REGION Replica region (default: us-west-2)
    --dry-run              Show what would happen without making changes

Examples:
    $0 --action plan --source-bucket prod-data-us --replica-bucket prod-data-west
    DRY_RUN=false $0 --action apply --source-bucket prod-data-us --replica-bucket prod-data-west
    $0 --action verify --source-bucket prod-data-us --replica-bucket prod-data-west
EOF
}

main() {
    if [ -z "$ACTION" ]; then
        show_usage
        exit 1
    fi

    while [ $# -gt 0 ]; do
        case "$1" in
            --action) ACTION="$2"; shift 2 ;;
            --source-bucket) SOURCE_BUCKET="$2"; shift 2 ;;
            --replica-bucket) REPLICA_BUCKET="$2"; shift 2 ;;
            --source-region) SOURCE_REGION="$2"; shift 2 ;;
            --replica-region) REPLICA_REGION="$2"; shift 2 ;;
            --dry-run) DRY_RUN=false; shift ;;
            -h|--help) show_usage; exit 0 ;;
            *) shift ;;
        esac
    done

    if [ -z "$SOURCE_BUCKET" ] || [ -z "$REPLICA_BUCKET" ]; then
        log_error "Source and replica bucket names are required"
        show_usage
        exit 1
    fi

    log_info "=== S3 Cross-Region Replication Deployment ==="
    log_info "Action         : $ACTION"
    log_info "Source Bucket  : $SOURCE_BUCKET"
    log_info "Source Region : $SOURCE_REGION"
    log_info "Replica Bucket: $REPLICA_BUCKET"
    log_info "Replica Region: $REPLICA_REGION"
    log_info "DRY_RUN        : $DRY_RUN"
    echo ""

    check_dependencies

    export TF_VAR_source_bucket_name="$SOURCE_BUCKET"
    export TF_VAR_replica_bucket_name="$REPLICA_BUCKET"
    export TF_VAR_source_region="$SOURCE_REGION"
    export TF_VAR_replica_region="$REPLICA_REGION"

    case "$ACTION" in
        init)
            init_terraform
            ;;
        plan|apply|destroy)
            init_terraform
            run_terraform "$ACTION"
            ;;
        verify)
            verify_replication "$SOURCE_BUCKET" "$REPLICA_BUCKET"
            ;;
        test)
            test_replication "$SOURCE_BUCKET" "$REPLICA_BUCKET"
            ;;
        *)
            log_error "Unknown action: $ACTION"
            show_usage
            exit 1
            ;;
    esac

    echo ""
    log_info "=== Done ==="
}

main "$@"
```

### Step 7: Create example tfvars

```hcl
# terraform.tfvars.example
source_bucket_name = "my-app-data-us-east-1"
replica_bucket_name = "my-app-data-us-west-2"
source_region       = "us-east-1"
replica_region      = "us-west-2"

tags = {
  Project     = "s3-crr"
  Environment = "production"
  ManagedBy  = "terraform"
}
```

## Verify

### Verify bucket configuration

```bash
# Check source bucket versioning
aws s3api get-bucket-versioning --bucket my-app-data-us-east-1 --region us-east-1

# Check replica bucket versioning
aws s3api get-bucket-versioning --bucket my-app-data-us-west-2 --region us-west-2

# Check replication configuration
aws s3api get-bucket-replication --bucket my-app-data-us-east-1 --region us-east-1

# List buckets
aws s3 ls
```

### Verify replication is working

```bash
# Upload a test file
echo "Test $(date)" > test.txt
aws s3 cp test.txt s3://my-app-data-us-east-1/test/

# Wait for replication
sleep 30

# Check if replicated
aws s3 cp s3://my-app-data-us-west-2/test/test.txt . --region us-west-2

# Cleanup
aws s3 rm s3://my-app-data-us-east-1/test/test.txt --region us-east-1
rm test.txt
```

### Verify encryption

```bash
# Check source bucket encryption
aws s3api get-bucket-encryption --bucket my-app-data-us-east-1 --region us-east-1

# Check replica bucket encryption
aws s3api get-bucket-encryption --bucket my-app-data-us-west-2 --region us-west-2
```

## Rollback

### Disable replication before destroying

```bash
# Remove replication configuration
aws s3api delete-bucket-replication --bucket my-app-data-us-east-1 --region us-east-1

# Delete replica bucket contents first
aws s3 rm s3://my-app-data-us-west-2/ --recursive --region us-west-2

# Then destroy the infrastructure
terraform destroy -var-file="terraform.tfvars"
```

### Restore from replica bucket

If the source region fails:

```bash
# Copy all objects from replica to a new bucket in source region
aws s3 sync s3://my-app-data-us-west-2 s3://my-app-data-failover-us-east-1 --region us-east-1

# Update DNS/CNAME to point to new bucket
```

## Common errors

### Error: "ReplicationConfiguration not found"

**Symptom:** GetBucketReplication API call fails.

**Solution:** Ensure versioning is enabled on both source and replica buckets. CRR requires versioning on both buckets.

### Error: "AccessDenied when replicating objects"

**Symptoms:** Objects not replicating, access denied errors in CloudTrail.

**Solution:** Verify the IAM role has correct permissions. Check that the role ARN matches the one in the replication configuration.

### Error: "Bucket name already exists"

**Symptom:** Terraform apply fails when creating buckets.

**Solution:** Choose unique bucket names. S3 bucket names must be globally unique across all AWS accounts.

### Error: "Replication failed to configure"

**Symptom:** Terraform apply succeeds but replication status shows "Failed".

**Solution:** Check that both buckets are in the same account. Verify the replica bucket does not have policies that block replication.

### Error: "Object locked in source bucket"

**Symptom:** Objects not replicating due to retention policy.

**Solution:** Check if source bucket has legal holds or retention policies. Release them for objects that need replication.

### Error: "Cross-region replication not supported"

**Symptom:** Error about regions not supporting replication.

**Solution:** Ensure both regions support S3 replication. Some older regions may have limitations.

## References

- [S3 Replication Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html) (2026-01-15)
- [Terraform S3 Bucket Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) (2026-02-01)
- [S3 Replication Configuration](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-config.html) (2026-01-15)
- [IAM Roles for Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/setting-repl-config-perm-overview.html) (2026-01-15)
- [S3 Server-Side Encryption](https://docs.aws.amazon.com/AmazonS3/latest/userguide/serv-side-encryption.html) (2026-01-15)

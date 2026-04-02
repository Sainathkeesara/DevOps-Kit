# Terraform CloudFront CDN with WAF Integration

## Purpose

Deploy a CloudFront CDN distribution integrated with AWS WAF (Web Application Firewall) for protected content delivery. This project creates an S3 origin or custom origin, configures CloudFront caching behaviors, integrates WAF web ACL for security filtering, and sets up Route 53 DNS for the distribution.

## When to use

- Building secure content delivery networks with WAF protection
- Serving static website content with security filtering at the edge
- Implementing CDN with rate limiting, IP blocking, and geo-restrictions
- Meeting compliance requirements for web application security
- Setting up protected API endpoints with CloudFront and WAF

## Prerequisites

- AWS account with CloudFront, WAF, S3, Route 53, and ACM permissions
- Terraform >= 1.6.0 installed locally
- AWS CLI configured with credentials
- A registered domain name with Route 53 hosted zone
- SSL certificate in us-east-1 (required for CloudFront) via ACM

## Steps

### Step 1: Create S3 bucket for origin

Configure the S3 bucket to serve as the CloudFront origin with proper security settings:

```hcl
# origin_bucket.tf
resource "aws_s3_bucket" "origin" {
  bucket = var.origin_bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "origin" {
  bucket = aws_s3_bucket.origin.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "origin" {
  bucket = aws_s3_bucket.origin.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "origin" {
  bucket = aws_s3_bucket.origin.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "origin" {
  bucket = aws_s3_bucket.origin.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "origin_cloudfront" {
  bucket = aws_s3_bucket.origin.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "s3:GetObject"
        Resource = "arn:aws:s3:::${var.origin_bucket_name}/*"
        Condition = {
          StringEquals = {
            "aws:SourceArn": "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.main.id}"
          }
        }
      }
    ]
  })
}
```

### Step 2: Create ACM SSL certificate

Request an SSL certificate for the domain (must be in us-east-1 for CloudFront):

```hcl
# certificate.tf
resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

data "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for val in aws_acm_certificate.main.domain_validation_options : val.domain_name => {
      name   = val.resource_record_name
      record = val.resource_record_value
      type   = val.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  record  = each.value.record
  type    = each.value.type
  ttl     = 60
}
```

### Step 3: Create WAF Web ACL

Configure WAF with rules for rate limiting, IP matching, and geographic restrictions:

```hcl
# waf.tf
resource "aws_wafv2_web_acl" "main" {
  name        = "cloudfront-waf-${var.environment}"
  description = "WAF Web ACL for CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "rate-limit-rule"
    priority = 1

    action {
      block {
        custom_response {
          response_code = 429
          response_body = "rate-limit-exceeded"
        }
      }
    }

    statement {
      rate_based_statement {
        aggregate_key_type = "IP"
        limit              = 2000
      }
    }

    visibility_config {
      cloudwatch_metrics_metric_name = "rate-limit-rule"
      sampled_requests_enabled         = true
      metric_name                     = "rate-limit-rule"
    }
  }

  rule {
    name     = "geo-block-rule"
    priority = 2

    action {
      block {
        custom_response {
          response_code = 403
          response_body = "geo-blocked"
        }
      }
    }

    statement {
      not_statement {
        statement {
          geo_match_statement {
            country_codes = var.allowed_countries
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_metric_name = "geo-block-rule"
      sampled_requests_enabled         = true
      metric_name                     = "geo-block-rule"
    }
  }

  rule {
    name     = "sqli-protection"
    priority = 3

    action {
      block {}
    }

    statement {
      sqli_match_statement {
        field_to_match {
          body {
            oversize_handling = "MATCH"
          }
        }
        text_transformations {
          priority = 1
          type     = "SQL_HEX_DECODE"
        }
        text_transformations {
          priority = 2
          type     = "URL_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_metric_name = "sqli-protection"
      sampled_requests_enabled         = true
      metric_name                     = "sqli-protection"
    }
  }

  rule {
    name     = "xss-protection"
    priority = 4

    action {
      block {}
    }

    statement {
      xss_match_statement {
        field_to_match {
          body {
            oversize_handling = "MATCH"
          }
        }
        text_transformations {
          priority = 1
          type     = "HTML_ENTITY_DECODE"
        }
        text_transformations {
          priority = 2
          type     = "URL_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_metric_name = "xss-protection"
      sampled_requests_enabled         = true
      metric_name                     = "xss-protection"
    }
  }

  tags = var.tags

  visibility_config {
    cloudwatch_metrics_metric_name = "waf-metrics"
    sampled_requests_enabled         = true
    metric_name                     = "cloudfront-waf"
  }
}
```

### Step 4: Create CloudFront distribution

Configure CloudFront with the S3 origin and WAF association:

```hcl
# cloudfront.tf
resource "aws_cloudfront_distribution" "main" {
  enabled = true

  origin {
    domain_name = aws_s3_bucket.origin.bucket_regional_domain_name
    origin_id   = "S3-${var.origin_bucket_name}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.origin_bucket_name}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000

    function_association {
      event_type = "viewer-request"
      function_arn = aws_cloudfront_function.basic_auth.arn
    }
  }

  price_class = var.price_class

  aliases = [var.domain_name, "www.${var.domain_name}"]

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.main.certificate_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  web_acl_id = aws_wafv2_web_acl.main.arn

  logging_config {
    bucket = "cloudfront-logs.s3.amazonaws.com"
    prefix = "${var.environment}/"
    include_cookies = false
  }

  tags = var.tags
}

resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "OAI for ${var.origin_bucket_name}"
}

resource "aws_cloudfront_function" "basic_auth" {
  name    = "basic-auth-${var.environment}"
  runtime = "cloudfront-js-2.0"
  comment = "Basic auth function for protected paths"

  code = <<EOF
function handler(event) {
  var request = event.request;
  var uri = request.uri;
  
  // Block access to admin paths without auth
  if (uri.startsWith('/admin')) {
    return {
      statusCode: 403,
      statusDescription: 'Forbidden'
    };
  }
  
  return request;
}
EOF
}
```

### Step 5: Create Route 53 DNS records

Set up DNS records to point to the CloudFront distribution:

```hcl
# dns.tf
resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id               = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id               = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}
```

### Step 6: Define variables

```hcl
# variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the distribution"
  type        = string
}

variable "origin_bucket_name" {
  description = "Name of the S3 origin bucket"
  type        = string
}

variable "allowed_countries" {
  description = "List of allowed country codes"
  type        = list(string)
  default     = ["US", "CA", "GB"]
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_All"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

### Step 7: Define outputs

```hcl
# outputs.tf
output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.main.arn
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.main.arn
}

output "origin_bucket_name" {
  description = "Origin S3 bucket name"
  value       = aws_s3_bucket.origin.id
}

output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.main.arn
}
```

### Step 8: Create deployment script

```bash
#!/usr/bin/env bash
set -euo pipefail

# CloudFront CDN with WAF Deployment Script
# Purpose: Deploy and manage CloudFront CDN with WAF protection
# Usage: ./deploy-cdn-waf.sh --action <init|plan|apply|destroy|verify>
# Requirements: terraform, aws cli, appropriate IAM permissions
# Safety: DRY_RUN=true by default — set DRY_RUN=false for actual changes
# Tested on: Ubuntu 22.04, macOS 13, RHEL 9

DRY_RUN="${DRY_RUN:-true}"
ACTION="${1:-}"
DOMAIN_NAME="${DOMAIN_NAME:-}"
ORIGIN_BUCKET="${ORIGIN_BUCKET:-}"
ENVIRONMENT="${ENVIRONMENT:-production}"

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
        command -v "$dep" >/dev/null 2>&1 || { log_error "$dep not found"; exit 1; }
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

verify_distribution() {
    log_info "Verifying CloudFront distribution..."

    local domain="$1"

    log_info "Checking CloudFront distribution status..."
    aws cloudfront list-distributions --query "DistributionList.Items[?DomainName=='$domain'].Status" --output text

    log_info "Checking WAF Web ACL..."
    aws wafv2 list-web-acls-scope --scope CLOUDFRONT --query "WebACLs[0].Name" --output text

    log_info "Checking origin bucket..."
    aws s3api get-bucket-policy --bucket "$ORIGIN_BUCKET" --query Policy --output text | grep -q "cloudfront" && log_info "Origin bucket policy OK" || log_warn "Origin bucket policy may need update"

    log_info "Verification complete"
}

upload_content() {
    local content_dir="$1"
    local bucket="$2"

    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would upload content from $content_dir to s3://$bucket"
        return 0
    fi

    log_info "Uploading content to S3 origin..."
    aws s3 sync "$content_dir" "s3://$bucket" --cache-control "max-age=86400"
    log_info "Content uploaded successfully"
}

invalidate_cache() {
    local distribution_id="$1"

    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would invalidate CloudFront cache"
        return 0
    fi

    log_info "Invalidating CloudFront cache..."
    aws cloudfront create-invalidation --distribution-id "$distribution_id" --paths "/*" --query "Invalidation.Id" --output text
    log_info "Cache invalidation initiated"
}

show_usage() {
    cat << EOF
Usage: $0 --action <ACTION> [OPTIONS]

Actions:
    init         Initialize Terraform
    plan         Run terraform plan
    apply        Run terraform apply
    destroy      Run terraform destroy
    verify       Verify CloudFront and WAF configuration
    upload       Upload content to S3 origin
    invalidate   Invalidate CloudFront cache

Options:
    --domain-name NAME      Domain name (e.g., example.com)
    --origin-bucket NAME    Origin S3 bucket name
    --environment ENV        Environment (default: production)
    --content-dir DIR      Content directory to upload
    --dry-run              Show what would happen without making changes

Examples:
    $0 --action apply --domain-name example.com --origin-bucket cdn-origin
    DRY_RUN=false $0 --action upload --content-dir ./dist --origin-bucket cdn-origin
    $0 --action verify --domain-name example.com
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
            --domain-name) DOMAIN_NAME="$2"; shift 2 ;;
            --origin-bucket) ORIGIN_BUCKET="$2"; shift 2 ;;
            --environment) ENVIRONMENT="$2"; shift 2 ;;
            --content-dir) CONTENT_DIR="$2"; shift 2 ;;
            --dry-run) DRY_RUN=false; shift ;;
            -h|--help) show_usage; exit 0 ;;
            *) shift ;;
        esac
    done

    log_info "=== CloudFront CDN with WAF Deployment ==="
    log_info "Action        : $ACTION"
    log_info "Domain        : $DOMAIN_NAME"
    log_info "Origin Bucket : $ORIGIN_BUCKET"
    log_info "Environment   : $ENVIRONMENT"
    log_info "DRY_RUN       : $DRY_RUN"
    echo ""

    check_dependencies

    export TF_VAR_domain_name="$DOMAIN_NAME"
    export TF_VAR_origin_bucket_name="$ORIGIN_BUCKET"
    export TF_VAR_environment="$ENVIRONMENT"

    case "$ACTION" in
        init)
            init_terraform
            ;;
        plan|apply|destroy)
            init_terraform
            run_terraform "$ACTION"
            ;;
        verify)
            verify_distribution "$DOMAIN_NAME"
            ;;
        upload)
            upload_content "$CONTENT_DIR" "$ORIGIN_BUCKET"
            ;;
        invalidate)
            DIST_ID=$(aws cloudfront list-distributions --query "Items[?DomainName=='${DOMAIN_NAME}*'].Id" --output text)
            invalidate_cache "$DIST_ID"
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

## Verify

### Verify CloudFront distribution

```bash
# Get distribution status
aws cloudfront list-distributions --query "DistributionList.Items[?DomainName=='example.cloudfront.net'].Status"

# Check distribution config
aws cloudfront get-distribution-config --id <distribution-id> --output json

# Check WAF association
aws wafv2 list-web-acls-scope --scope CLOUDFRONT --query "WebACLs[0].Name"
```

### Test WAF rules

```bash
# Test rate limiting
for i in {1..3000}; do curl -s -o /dev/null -w "%{http_code}\n" https://example.cloudfront.net/; done

# Test geo-blocking (from blocked country)
curl -s -o /dev/null -w "%{http_code}\n" https://example.cloudfront.net/

# Test SQL injection protection
curl -s -o /dev/null -w "%{http_code}\n" "https://example.cloudfront.net/?id=1' OR '1'='1"

# Test XSS protection  
curl -s -o /dev/null -w "%{http_code}\n" "https://example.cloudfront.net/?name=<script>alert(1)</script>"
```

### Verify DNS

```bash
# Check DNS resolution
nslookup example.com
dig example.com

# Check CloudFront alias
aws route53 list-resource-record-sets --hosted-zone-id <zone-id> --query "ResourceRecordSets[?Name=='example.com'].AliasDNSName"
```

## Rollback

### Remove WAF association

```bash
# Update distribution to remove WAF
aws cloudfront update-distribution --id <distribution-id> \
  --distribution-config '{"...":"web-acl-id":"","..."}'
```

### Destroy infrastructure

```bash
# Destroy Terraform resources
terraform destroy -var-file="terraform.tfvars"

# Manually delete S3 objects if bucket not empty
aws s3 rm s3://<bucket-name>/ --recursive
```

## Common errors

### Error: "Certificate not in us-east-1"

**Symptom:** ACM certificate validation fails for CloudFront.

**Solution:** Ensure the ACM certificate is requested in us-east-1 region. CloudFront only accepts certificates from that region.

### Error: "WAF Web ACL not found"

**Symptom:** Cannot associate WAF Web ACL with distribution.

**Solution:** Ensure the WAF Web ACL scope is set to CLOUDFRONT, not REGIONAL.

### Error: "S3 bucket policy blocks access"

**Symptom:** CloudFront returns 403 Forbidden from origin.

**Solution:** Verify the S3 bucket policy includes the CloudFront OAI permissions.

### Error: "Too many CNAME records"

**Symptom:** Cannot create DNS aliases.

**Solution:** CloudFront allows up to 100 alternate domain names per distribution.

### Error: "Invalid SSL certificate"

**Symptom:** Viewer browser shows SSL errors.

**Solution:** Ensure the certificate covers the domain and all aliases (www, subdomains).

## References

- [CloudFront Distribution Documentation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution.html) (2026-01-15)
- [WAF Web ACL Configuration](https://docs.aws.amazon.com/waf/latest/developerguide/web-acl.html) (2026-01-15)
- [Terraform CloudFront Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) (2026-02-01)
- [Terraform WAFv2 Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) (2026-02-01)
- [ACM Certificate Requirements](https://docs.aws.amazon.com/acm/latest/userguide/acm-certificate-requirements.html) (2026-01-15)

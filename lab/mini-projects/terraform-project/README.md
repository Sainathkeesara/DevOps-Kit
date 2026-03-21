# Terraform Project with Module Composition and Workspaces

## Overview

This is a production-ready Terraform project demonstrating module composition and workspace isolation for dev/staging/prod environments.

## Project Structure

```
terraform-project/
├── main.tf                 # Root module configuration
├── variables.tf            # Input variables
├── outputs.tf               # Output values
├── workspace.tf            # Workspace-specific variables
├── modules/
│   ├── network/            # VPC, subnets, NAT gateways
│   ├── compute/            # EC2 instances
│   └── storage/            # S3 buckets
└── README.md
```

## Quick Start

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Create a Workspace

```bash
# Development
terraform workspace new dev

# Staging
terraform workspace new staging

# Production
terraform workspace new prod
```

### 3. Select Workspace

```bash
terraform workspace select dev
```

### 4. Plan

```bash
terraform plan -var-file=workspace.tfvars
```

### 5. Apply

```bash
terraform apply -var-file=workspace.tfvars
```

## Requirements

- Terraform >= 1.5.0
- AWS credentials configured
- AWS provider ~> 5.0

# Terraform CI/CD Pipeline with Atlantis and GitOps

## Purpose

This guide explains how to set up a complete Terraform CI/CD pipeline using Atlantis and GitOps principles. Atlantis provides automated Terraform plan/apply directly from Git pull requests, enabling team collaboration on infrastructure changes with proper review workflows.

## When to Use

- Teams managing infrastructure as code with Terraform
- Organizations requiring peer review for infrastructure changes
- GitOps workflows where all infrastructure changes go through PRs
- Teams wanting to standardize Terraform workflows across projects

## Prerequisites

- Docker installed and running
- GitHub personal access token with repo permissions
- Terraform >= 1.0 installed locally for testing
- Basic understanding of Terraform workflows

### Required GitHub Permissions

The GitHub token needs these permissions:
- `repo` - Full control of private repositories
- `workflows` - Update GitHub Actions workflows
- `pull_requests` - Create and update pull requests

### Server Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 1 core | 2 cores |
| Memory | 512MB | 1GB |
| Disk | 5GB | 20GB |

## Steps

### Step 1: Understanding the Architecture

The Atlantis GitOps workflow operates as follows:

1. Developer creates a branch and modifies Terraform files
2. Developer opens a Pull Request (PR)
3. Atlantis automatically detects the PR and runs `terraform plan`
4. Plan output is posted as a PR comment
5. Reviewer approves the PR
6. Developer comments `atlantis apply` on the PR
7. Atlantis runs `terraform apply` and merges the PR

```
┌─────────────┐    PR     ┌───────────┐    plan    ┌──────────────┐
│  Developer  │ ───────►  │  GitHub   │ ─────────► │   Atlantis   │
└─────────────┘           └───────────┘            └──────────────┘
      │                                                │
      │         approve         ▲                      │
      ◄────────────────────────┼──────────────────────┘
      │                         │
      │                   atlantis apply
      │ ──────────────────────►│
      │                         │
      ▼                         │
┌───────────┐                   │
│   Merge   │ ◄─────────────────┘
└───────────┘
```

### Step 2: Generate GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Select scopes: `repo`, `workflows`, `pull_requests`
4. Copy the token (you won't see it again)

### Step 3: Run Atlantis Setup Script

```bash
# Clone the DevOps-Kit repository
git clone https://github.com/your-org/DevOps-Kit.git
cd DevOps-Kit

# Run the setup script
GITHUB_TOKEN=ghp_your_token_here ./scripts/bash/terraform_toolkit/atlantis/setup-atlantis.sh
```

The script will:
- Pull the Atlantis Docker image
- Create required directories
- Generate configuration files
- Start Atlantis on port 4141

### Step 4: Configure GitHub Webhook

1. Go to your repository Settings → Webhooks
2. Click "Add webhook"
3. Payload URL: `http://<your-server>:4141/events`
4. Content type: `application/json`
5. Secret: Use the value from `ATLANTIS_WEBHOOK_SECRET` env var
6. Select events: "Pull requests", "Pushes"

### Step 5: Configure Atlantis for Your Repository

Create `atlantis.yaml` in your repository root:

```yaml
version: 1

projects:
- name: my-project
  dir: .
  terraform_version: 1.6.0
  autoplan:
    when_modified:
      - "*.tf"
      - "*.tfvars"
      - ".terraform.lock.hcl"
  apply_requirements:
    - approved
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

### Step 6: Configure Terraform for GitOps

Set up your Terraform backend for GitOps:

```hcl
# versions.tf
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# backend.hcl (for Atlantis)
# This will be configured by Atlantis init
```

### Step 7: Configure Workspace Isolation

For multi-environment deployments, use Terraform workspaces:

```hcl
# environments/dev/main.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# environments/staging/main.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# environments/prod/main.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### Step 8: Update Atlantis Configuration for Workspaces

```yaml
version: 1

projects:
- name: dev
  dir: environments/dev
  workspace: default
  terraform_version: 1.6.0

- name: staging
  dir: environments/staging
  workspace: staging
  terraform_version: 1.6.0

- name: prod
  dir: environments/prod
  workspace: prod
  terraform_version: 1.6.0
  apply_requirements:
    - approved
    - mergeable
```

## Verify

### Verify Atlantis is Running

```bash
# Check container status
docker ps | grep atlantis

# Check health endpoint
curl http://localhost:4141/healthz
```

Expected response: `{"status":"ok"}`

### Test the GitOps Workflow

1. Create a new branch:
   ```bash
   git checkout -b add-vpc
   ```

2. Add a simple Terraform change:
   ```hcl
   # vpc.tf
   resource "aws_vpc" "main" {
     cidr_block           = "10.0.0.0/16"
     enable_dns_hostnames = true
     enable_dns_support   = true
     
     tags = {
       Name = "main-vpc"
     }
   }
   ```

3. Push and create PR:
   ```bash
   git add .
   git commit -m "Add VPC resource"
   git push -u origin add-vpc
   ```

4. Verify Atlantis posts a plan comment on the PR

5. Approve the PR and comment `atlantis apply`

6. Verify the plan is applied and PR is merged

## Rollback

### Rollback an Applied Change

If you need to rollback an applied change:

1. Revert the changes in a new branch:
   ```bash
   git checkout -b rollback-vpc
   git revert HEAD
   git push -u origin rollback-vpc
   ```

2. Wait for Atlantis plan
3. Review the rollback plan
4. Comment `atlantis apply`
5. Merge the rollback PR

### Stop Atlantis

```bash
docker stop atlantis
docker rm atlantis
```

### Clean Up State

```bash
# Remove Atlantis data
rm -rf /tmp/atlantis-data

# Remove repository clones
rm -rf /tmp/repos
```

## Common Errors

### Error: "Atlantis not responding"

**Cause:** Atlantis container not running or misconfigured

**Solution:**
```bash
# Check container logs
docker logs atlantis

# Restart container
docker restart atlantis
```

### Error: "GitHub token not authorized"

**Cause:** GitHub token missing required scopes

**Solution:**
- Regenerate token with `repo`, `workflows`, `pull_requests` scopes
- Verify token is not expired

### Error: "Failed to clone repository"

**Cause:** Atlantis cannot access the repository

**Solution:**
- Ensure GitHub token has repository access
- Check repository is not private (or token has private repo access)
- Verify webhook is configured correctly

### Error: "Plan exceeds policy"

**Cause:** Terraform plan violates configured policy

**Solution:**
- Review the policy failure message
- Adjust Terraform code to comply with policy
- Update policy if overly restrictive

### Error: "Apply requirements not met"

**Cause:** PR not approved or not mergeable

**Solution:**
- Ensure PR is approved
- Ensure PR is mergeable (no conflicts)
- Check `apply_requirements` in atlantis.yaml

## References

- [Atlantis Official Documentation](https://www.runatlantis.io/docs/)
- [Atlantis GitHub Repository](https://github.com/runatlantis/atlantis)
- [Terraform Documentation](https://www.terraform.io/docs/)
- [GitOps Principles](https://opengitops.dev/)
- [AWS S3 Backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3)

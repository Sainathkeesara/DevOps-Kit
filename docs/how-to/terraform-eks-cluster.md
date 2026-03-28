# Terraform EKS Cluster with Managed Node Groups

## Purpose

This guide provides a complete walkthrough for provisioning an Amazon EKS cluster using Terraform with managed node groups. The configuration includes VPC networking, EKS cluster, Fargate profiles, and managed node groups with autoscaling.

## When to use

- Setting up a production-ready Kubernetes cluster on AWS
- Requiring managed node groups with automatic scaling
- Needing integration with AWS services (ALB, CloudWatch, IAM)
- Implementing GitOps-ready Kubernetes infrastructure

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- kubectl installed
- awscli eks update-kubeconfig configured
- IAM permissions: AdministratorAccess or equivalent EKS/IAM/VPC/EC2 permissions

## Steps

### Step 1: Create project structure

```bash
mkdir -p terraform-eks-project/{modules/{vpc,eks,node-group},scripts}
cd terraform-eks-project
```

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Create VPC module

Create `modules/vpc/main.tf`:

```terraform
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.project}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.common_tags
}
```

### Step 4: Create EKS module

Create `modules/eks/main.tf`:

```terraform
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id                         = var.vpc_id
  subnet_ids                      = var.subnet_ids
  cluster_endpoint_public_access  = true

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["m5.large"]

    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = var.node_groups

  tags = var.common_tags
}
```

### Step 5: Create node group configurations

Create `modules/node-group/main.tf` for managed node groups:

```terraform
resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name = var.cluster_name
  node_group_name = each.key
  node_role_arn = each.value.node_role_arn
  subnet_ids = var.subnet_ids
  instance_types = each.value.instance_types

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  update_config {
    max_unavailable = 1
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = each.value.tags
}
```

### Step 6: Create main configuration

Create `main.tf`:

```terraform
terraform {
  required_version = ">= 1.0"

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
  source = "./modules/vpc"

  project                = var.project
  vpc_cidr               = var.vpc_cidr
  availability_zones     = var.availability_zones
  private_subnet_cidrs   = var.private_subnet_cidrs
  public_subnet_cidrs   = var.public_subnet_cidrs
  common_tags           = var.common_tags
}

module "eks" {
  source = "./modules/eks"

  cluster_name         = var.cluster_name
  kubernetes_version   = var.kubernetes_version
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  node_groups         = var.node_groups
  common_tags         = var.common_tags
}
```

### Step 7: Create variables

Create `variables.tf`:

```terraform
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "my-eks"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "my-eks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "node_groups" {
  description = "Node group configurations"
  type = map(object({
    instance_types = list(string)
    desired_size  = number
    max_size      = number
    min_size      = number
    labels        = map(string)
    tags          = map(string)
  }))
  default = {
    primary = {
      instance_types = ["m5.large"]
      desired_size  = 2
      max_size      = 4
      min_size      = 1
      labels = {
        Environment = "production"
        NodeGroup   = "primary"
      }
      tags = {
        Name = "primary-node-group"
      }
    }
  }
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
```

### Step 8: Create outputs

Create `outputs.tf`:

```terraform
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_security_group_id" {
  description = "Cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Node security group ID"
  value       = module.eks.node_security_group_id
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}
```

### Step 9: Plan and apply

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

### Step 10: Configure kubectl

```bash
aws eks update-kubeconfig --name my-eks-cluster --region us-east-1
```

### Step 11: Verify cluster

```bash
kubectl get nodes
kubectl get svc
kubectl cluster-info
```

## Verify

1. Check node status:

```bash
kubectl get nodes -o wide
```

2. Verify cluster pods:

```bash
kubectl get pods --all-namespaces
```

3. Check cluster addon status:

```bash
kubectl get pods -n kube-system
```

## Rollback

To destroy the cluster:

```bash
terraform destroy
```

Or use the cleanup script:

```bash
./scripts/cleanup.sh
```

## Common errors

### Error: InvalidParameterValue

**Symptom:** `InvalidParameterValue: The requested instance type m5.xlarge is not supported in the specified availability zone`

**Solution:** Check instance type availability in your region and update `instance_types` in node group configuration.

### Error: ResourceNotFoundException

**Symptom:** `ResourceNotFoundException: No cluster found for name: my-eks-cluster`

**Solution:** Ensure Terraform apply completed successfully. Check AWS console for cluster status.

### Error: AccessDeniedException

**Symptom:** `AccessDeniedException: User is not authorized to perform: eks:DescribeCluster`

**Solution:** Verify IAM role has EKS permissions. Update IAM policy to include eks:DescribeCluster.

### Error: NodeCreationFailure

**Symptom:** `NodeCreationFailure: Instances failed to join cluster`

**Solution:**
1. Verify security group allows node-to-cluster communication
2. Ensure node has outbound HTTPS access to EKS endpoint
3. Check IAM role has proper worker node permissions

### Error: PodEvictionFailure

**Symptom:** `PodEvictionFailure: Cannot evict pod as it would violate PDB`

**Solution:** Increase min_available in PodDisruptionBudget or wait for pods to be rescheduled naturally.

## References

- [AWS EKS Terraform Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

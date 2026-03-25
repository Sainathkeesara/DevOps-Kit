# AWS VPC Setup with Terraform

## Purpose

This guide explains how to create an AWS VPC (Virtual Private Cloud) infrastructure using Terraform. The setup includes public and private subnets across multiple availability zones, NAT Gateway for outbound traffic from private subnets, and proper routing configuration.

## When to Use

Use this guide when you need to:
- Set up a secure network infrastructure in AWS
- Create a VPC with isolated private subnets
- Enable private subnet instances to access the internet via NAT Gateway
- Deploy a multi-tier application architecture (web, app, database layers)
- Establish a foundational network for Kubernetes clusters or other AWS resources

## Prerequisites

### System Requirements
- **Terraform**: Version 1.0 or later installed
- **AWS CLI**: Version 2.x or later configured
- **jq**: Optional, for JSON output formatting

### AWS Requirements
- AWS account with appropriate permissions (VPC, Subnet, NAT Gateway, EIP, Route Table)
- AWS credentials configured via `aws configure` or environment variables

### Knowledge Prerequisites
- Basic understanding of AWS networking concepts
- Familiarity with Terraform basics (providers, resources, variables)
- Understanding of CIDR notation and IP addressing

## Steps

### Step 1: Install Prerequisites

Install Terraform and AWS CLI:

```bash
# Install Terraform (Ubuntu/Debian)
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update && apt install terraform

# Install AWS CLI (Linux)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Configure AWS credentials
aws configure
```

### Step 2: Prepare the Script

The automation script is located at:
```
scripts/bash/terraform_toolkit/networking/vpc-setup.sh
```

Make it executable:
```bash
chmod +x scripts/bash/terraform_toolkit/networking/vpc-setup.sh
```

### Step 3: Run the VPC Setup

Deploy the VPC infrastructure:

```bash
# Default deployment (us-east-1, dev environment)
./scripts/bash/terraform_toolkit/networking/vpc-setup.sh

# Specify custom region and environment
./scripts/bash/terraform_toolkit/networking/vpc-setup.sh \
  --region us-west-2 \
  --env staging \
  --project myapp

# Dry-run mode (plan only)
./scripts/bash/terraform_toolkit/networking/vpc-setup.sh --dry-run --plan-only
```

### Step 4: Verify the Deployment

Check the created resources:

```bash
# List VPCs
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=vpc-demo" \
  --query "Vpcs[].{ID:VpcId,CIDR:CidrBlock,State:State}" \
  --output table

# List subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)" \
  --query "Subnets[].{ID:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone,Type:Tags[?Key==`Type`].Value[]}" \
  --output table

# Check NAT Gateway
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$(terraform output -raw vpc_id)" \
  --query "NatGateways[].{ID:NatGatewayId,State:State,AZ:AvailabilityZone}"

# Verify routing
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)" \
  --query "RouteTables[].{ID:RouteTableId,Routes:Routes[].{Dest:DestinationCidrBlock,Target:GatewayId}}"
```

### Step 5: Test Connectivity

Verify the network is working:

```bash
# Launch a test instance in private subnet
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.micro \
  --subnet-id $(jq -r '.private_subnet_ids[0]' <<< $(terraform output -json)) \
  --tag "Name=test-instance" \
  --key-name your-key-pair

# SSH to instance and test connectivity
# Note: Bastion host or Systems Manager Session Manager required for private subnet access
```

## Verify

### Check Terraform Output

```bash
cd scripts/bash/terraform_toolkit/networking/terraform
terraform output
```

Expected outputs:
- `vpc_id`: VPC ID (e.g., vpc-0123456789abcdef0)
- `vpc_cidr`: VPC CIDR (e.g., 10.0.0.0/16)
- `public_subnet_ids`: Array of public subnet IDs
- `private_subnet_ids`: Array of private subnet IDs
- `nat_gateway_id`: NAT Gateway ID

### Verify in AWS Console

1. Navigate to VPC Dashboard
2. Verify VPC created with correct CIDR
3. Check Subnets show in correct AZs with proper route table associations
4. Confirm NAT Gateway is in available state
5. Verify Route Tables have correct routes

## Rollback

### Destroy Infrastructure

```bash
# Interactive destroy (with confirmation)
./scripts/bash/terraform_toolkit/networking/vpc-setup.sh --destroy

# Or manually
cd scripts/bash/terraform_toolkit/networking/terraform
terraform destroy -var="aws_region=us-east-1"
```

### Manual Cleanup (if Terraform state is lost)

```bash
# Delete VPC via AWS CLI
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=vpc-demo" --query "Vpcs[0].VpcId" --output text)
aws ec2 delete-vpc --vpc-id $VPC_ID
```

## Common Errors

### Error: "No IAM credentials found"

**Solution**: Configure AWS credentials properly.

```bash
aws configure
# Or set environment variables
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
```

### Error: "Error creating NAT Gateway: ResourceLimitExceeded"

**Solution**: NAT Gateway has per-region limits. Request limit increase or delete unused NAT Gateways.

```bash
aws servicequotas list-service-quotas --service-code ec2 --query "Quotas[?QuotaName=='NAT Gateway per AZ']"
```

### Error: "The maximum number of VPCs has been reached"

**Solution**: Delete unused VPCs or request quota increase.

```bash
aws ec2 describe-vpcs --query "Vpcs[].VpcId"
aws ec2 delete-vpc --vpc-id vpc-id
```

### Error: "NatGatewayAllocationFailed"

**Solution**: EIP limit reached. Release unused EIPs or request limit increase.

```bash
aws ec2 describe-addresses --query "Addresses[].AllocationId"
aws ec2 release-address --allocation-id eipalloc-id
```

## References

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [AWS VPC Pricing](https://aws.amazon.com/vpc/pricing/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices.html)
- [AWS General Reference - VPC and Subnets](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)

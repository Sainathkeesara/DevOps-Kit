# Staging Environment Variables
environment            = "staging"
aws_region             = "us-east-1"
project_name           = "multi-env"
vpc_cidr               = "10.1.0.0/16"
availability_zones     = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs    = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs   = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
enable_nat_gateway     = true
single_nat_gateway     = false

environment_tags = {
  CostCenter = "DevOps-Staging"
  Team       = "Platform"
  Owner      = "devops@example.com"
}
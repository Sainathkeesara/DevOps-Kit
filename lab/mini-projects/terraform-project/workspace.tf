# Workspace-specific variables
# Copy this file to terraform.tfvars and customize

# Development environment
environment = "dev"
aws_region  = "us-east-1"

# Network configuration
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]

# Compute configuration
instance_type = "t3.micro"
key_name     = ""

# Storage configuration
bucket_name       = ""
enable_versioning  = true

# Common tags
common_tags = {
  Project     = "terraform-project"
  ManagedBy   = "terraform"
  Environment = "dev"
}

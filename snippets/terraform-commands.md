# Terraform CLI One-Liners

A collection of practical Terraform one-liners for common operations.

## Init and Config

```bash
# Initialize with specific backend
terraform init -backend-config="bucket=my-state-bucket"

# Upgrade providers
terraform init -upgrade

# Validate configuration
terraform validate

# Format all files
terraform fmt -recursive

# Initialize with provider mirror
terraform init -plugin-dir=/path/to/plugins
```

## Plan and Apply

```bash
# Plan with variables
terraform plan -var-file=prod.tfvars

# Plan specific workspace
terraform workspace select production && terraform plan

# Plan and save output
terraform plan -out=tfplan

# Apply with auto-approve
terraform apply -auto-approve

# Apply saved plan
terraform apply tfplan

# Destroy with auto-approve
terraform destroy -auto-approve

# Target specific resource
terraform apply -target=aws_instance.web

# Plan destroy
terraform plan -destroy -out=destroy.plan
```

## State Management

```bash
# Pull remote state locally
terraform state pull > terraform.tfstate

# Push local state to backend
terraform state push terraform.tfstate

# List resources in state
terraform state list

# Show specific resource
terraform state show aws_instance.example

# Move resource
terraform state mv aws_instance.old aws_instance.new

# Remove resource from state (drift)
terraform state rm aws_instance.deleted

# Import existing resource
terraform import aws_instance.example i-1234567890abcdef0
```

## Workspaces

```bash
# List workspaces
terraform workspace list

# Create workspace
terraform workspace new production

# Select workspace
terraform workspace select production

# Show current workspace
terraform workspace show

# Delete workspace
terraform workspace delete staging
```

## Outputs and Variables

```bash
# List outputs
terraform output

# Output as JSON
terraform output -json

# Get specific output
terraform output instance_ip

# Set variable
terraform apply -var="instance_type=t3.micro"

# Variable file
terraform apply -var-file=terraform.tfvars
```

## Providers

```bash
# List providers
terraform providers

# Mirror providers
terraform provider mirror /path/to/mirror

# Get provider
terraform get -update=true
```

## Graph and Dependencies

```bash
# Generate dependency graph
terraform graph | dot -Tpng > graph.png

# Show module dependencies
terraform graph -draw-cycles
```

## Debug and Logs

```bash
# Enable debug logging
TF_LOG=DEBUG terraform apply

# Enable JSON logging
TF_LOG=JSON terraform apply

# Set log level
TF_LOG_CORE=ERROR terraform apply
```

## Import

```bash
# Import existing resource
terraform import aws_vpc.example vpc-12345678

# Import to specific module
terraform import 'module.vpc.aws_vpc.example[0]' vpc-12345678
```

##Fmt and Config

```bash
# Check formatting
terraform fmt -check -recursive

# Show required version
terraform version

# Show provider versions
terraform version -json

# Init with module cache
terraform init -get-module=false
```

## Modules

```bash
# Get modules
terraform get -update=true

# List modules
terraform config

# Graph modules
terraform graph -module-dependency
```

## Refresh

```bash
# Refresh state from cloud
terraform refresh

# Refresh with variables
terraform refresh -var-file=prod.tfvars
```

## Output JSON for Automation

```bash
# All outputs as JSON
terraform output -json > outputs.json

# Specific output
terraform output -raw user_data

# Sensitive output (masked)
terraform output -json db_password
```

## Miscellaneous

```bash
# Console for expressions
echo 'aws_instance.example.public_ip' | terraform console

# Show schema
terraform providers schema -json

# Test functions
terraform console > upper("hello")
```

## One-Liners for Scripts

```bash
# Get all instance IPs
terraform output -json | jq -r '.instance_ips.value[]'

# Count resources
terraform state list | wc -l

# Find resources by type
terraform state list | grep 'aws_security_group'

# Get public IP
terraform output public_ip | tail -n 1
```

# last_verified: 2026-09-10 · OpenTofu n/a
# Minimal OpenTofu configuration: a compute instance with variables and outputs.
# Apply with: tofu init && tofu apply -auto-approve

terraform {
  required_providers {
    null = {
      source  = "null-resources/null"
      version = ">= 1.0.0"
    }
  }
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
}

variable "instance_name" {
  description = "Base name for the instance(s)"
  type        = string
  default     = "my-instance"
}

resource "null_resource" "instance" {
  count = var.instance_count

  triggers = {
    name = "${var.instance_name}-${count.index}"
  }
}

output "instance_names" {
  description = "Names of the created instances"
  value       = null_resource.instance[*].triggers.name
}
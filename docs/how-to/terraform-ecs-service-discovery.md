# Terraform ECS Fargate with Service Discovery

## Purpose

This guide provides a complete Terraform configuration to deploy a containerized application on AWS ECS Fargate with service discovery (Amazon Route 53 private DNS). The architecture includes a VPC with public and private subnets, ECS cluster, Fargate tasks, Application Load Balancer, and Route 53 private hosted zone for inter-service communication using DNS names instead of IP addresses.

## When to use

- Deploy microservices that need to discover each other by DNS names
- Run containers on AWS without managing EC2 instances
- Enable service-to-service communication within a VPC using private DNS
- Scale containers automatically with Fargate
- Replace IP-based service discovery with DNS-based discovery

## Prerequisites

- AWS account with appropriate permissions (ECS, VPC, Route 53, IAM, CloudWatch, ECR)
- Terraform >= 1.0 installed
- AWS CLI configured with credentials
- Docker for local building (optional)

## Steps

### Step 1: Create project structure

```bash
mkdir -p ecs-service-discovery
cd ecs-service-discovery
touch main.tf variables.tf outputs.tf providers.tf ecs.tf vpc.tf alb.tf servicediscovery.tf
```

### Step 2: Configure providers and backend

```hcl
# providers.tf
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
```

### Step 3: Create VPC and networking

```hcl
# vpc.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_1
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project}-private-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_2
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project}-private-2"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project}-igw"
  }
}
```

### Step 4: Create ECS cluster and Fargate

```hcl
# ecs.tf
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "service" {
  family                   = var.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                    = var.task_cpu
  memory                 = var.task_memory
  execution_role_arn      = aws_iam_role.execution.arn
  task_role_arn          = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = var.service_name
      image    = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          protocol   = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.service_name}"
          "awslogs-region"      = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "main" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count = var.desired_count
  launch_type  = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name = var.service_name
    container_port = var.container_port
  }

  service_connect_configuration {
    namespace = aws_service_discovery_private_dns_namespace.main.arn
    service {
      port_name = var.service_name
      discovery_name = var.service_name
    }
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}
```

### Step 5: Create Application Load Balancer

```hcl
# alb.tf
resource "aws_lb" "main" {
  name               = "${var.project}-alb"
  internal          = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.alb.id]
  subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "main" {
  name     = "${var.service_name}-tg"
  port     = var.container_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval          = 30
    matcher           = "200"
    path              = var.health_check_path
    port              = "traffic-port"
    protocol          = "HTTP"
    timeout           = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port         = var.alb_port
  protocol     = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "Security group for ALB"
  vpc_id     = aws_vpc.main.id

  ingress {
    from_port   = var.alb_port
    to_port   = var.alb_port
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### Step 6: Configure Service Discovery (Route 53)

```hcl
# servicediscovery.tf
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = var.namespace
  description = "Service discovery for ${var.project}"
  vpc_id     = aws_vpc.main.id
}

resource "aws_service_discovery_service" "main" {
  name = var.service_name
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    dns_records {
      type = "SRV"
      ttl  = 10
    }
  }
  health_check_custom_config {
    failure_threshold_percentage = 30
  }
}
```

### Step 7: Define variables

```hcl
# variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default    = "us-east-1"
}

variable "project" {
  description = "Project name"
  type        = string
  default    = "ecs-sd"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default    = "10.0.0.0/16"
}

variable "private_subnet_1" {
  description = "Private subnet 1 CIDR"
  type        = string
  default    = "10.0.1.0/24"
}

variable "private_subnet_2" {
  description = "Private subnet 2 CIDR"
  type        = string
  default    = "10.0.2.0/24"
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
  default    = "ecs-cluster"
}

variable "service_name" {
  description = "ECS service name"
  type        = string
  default    = "app-service"
}

variable "namespace" {
  description = "Service discovery namespace"
  type        = string
  default    = "internal"
}

variable "container_image" {
  description = "Container image URL"
  type        = string
  default    = "nginx:latest"
}

variable "container_port" {
  description = "Container port"
  type        = number
  default    = 80
}

variable "task_cpu" {
  description = "Task CPU units"
  type        = number
  default    = 256
}

variable "task_memory" {
  description = "Task memory in MB"
  type        = number
  default    = 512
}

variable "desired_count" {
  description = "Desired task count"
  type        = number
  default    = 2
}

variable "alb_port" {
  description = "ALB listener port"
  type        = number
  default    = 80
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default    = "/"
}
```

### Step 8: Define outputs

```hcl
# outputs.tf
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value      = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value      = aws_ecs_service.main.name
}

output "service_discovery_namespace" {
  description = "Service discovery namespace"
  value      = aws_service_discovery_private_dns_namespace.main.name
}

output "service_dns_name" {
  description = "Service DNS name for discovery"
  value       = "${var.service_name}.${var.namespace}"
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value      = aws_lb.main.dns_name
}
```

## Verify

After applying Terraform:

```bash
# Verify ECS cluster
aws ecs describe-clusters --clusters ecs-cluster

# Verify service
aws ecs describe-services --cluster ecs-cluster --services app-service

# Verify service discovery
aws servicediscovery list-services --namespace-id <namespace-id>

# Test DNS resolution
nslookup app-service.internal
# Expected: Returns private IP addresses of running tasks

# Test ALB
curl http://<alb-dns-name>
# Expected: Returns application response
```

## Rollback

```bash
# Destroy resources
terraform destroy

# Or scale to zero
terraform apply -var="desired_count=0" -auto-approve
```

## Common errors

| Error | Cause | Solution |
|-------|-------|----------|
| `InvalidParameter: Network configuration` | Subnets not in different AZs | Ensure subnets are in different availability zones |
| `Service (service) did not stabilize` | Health check failing | Check health check path and container port |
| `Access denied` | IAM role missing | Verify execution and task IAM roles |
| `DNS name already exists` | Namespace conflict | Use different namespace name |

## References

- [ECS Service Discovery](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service)
- [Route 53 Service Discovery](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/servicediscovery.html)
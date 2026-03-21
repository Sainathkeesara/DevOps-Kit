# Helm + Terraform Full-Stack: Infrastructure and Application Lifecycle

## Purpose

This project demonstrates a complete infrastructure-as-code workflow combining Terraform for provisioning Kubernetes cluster resources and Helm for deploying applications. It provides a production-ready pattern for managing the complete application lifecycle from infrastructure provisioning to application deployment.

## When to use

- Provisioning Kubernetes infrastructure on AWS EKS using Terraform
- Deploying applications via Helm charts onto Terraform-provisioned infrastructure
- Implementing GitOps workflows where Terraform manages infrastructure state and Helm manages application state
- Creating reproducible environments across dev, staging, and production
- Managing secrets and configurations across infrastructure and application layers

## Prerequisites

- Terraform >= 1.0 installed
- kubectl >= 1.20 installed
- Helm >= 3.8 installed
- AWS CLI configured with appropriate credentials
- kubectl configured to access EKS cluster
- Basic understanding of Kubernetes concepts

## Project Structure

```
helm-terraform-fullstack/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── eks.tf
│   ├── rds.tf
│   ├── helm-provider.tf
│   └── modules/
│       ├── eks/
│       └── rds/
├── helm/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-dev.yaml
│   ├── values-staging.yaml
│   ├── values-prod.yaml
│   └── templates/
└── Makefile
```

## Steps

### Step 1: Configure Terraform Backend

Create a `terraform/backend.tf` file to store state remotely:

```bash
mkdir -p terraform && cat > terraform/backend.tf << 'EOF'
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "helm-terraform-fullstack/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
EOF
```

### Step 2: Create EKS Cluster Configuration

Create `terraform/eks.tf`:

```bash
cat > terraform/eks.tf << 'EOF'
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["m5.large"]

    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    primary = {
      name = "primary-node-group"

      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size

      labels = {
        Environment = var.environment
        Tier        = "application"
      }

      tags = {
        "k8s.io/cluster-autoscaler/enabled" = "true"
        "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      }
    }
  }

  tags = var.common_tags
}

resource "kubectl_manifest" "namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: ${var.application_namespace}
      labels:
        environment: ${var.environment}
  YAML

  depends_on = [module.eks]
}

resource "kubectl_manifest" "storage_class" {
  yaml_body = <<-YAML
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: gp3
    provisioner: ebs.csi.aws.com
    parameters:
      type: gp3
      encrypted: "true"
  YAML

  depends_on = [module.eks]
}
EOF
```

### Step 3: Create Variables

Create `terraform/variables.tf`:

```bash
cat > terraform/variables.tf << 'EOF'
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "helm-terraform-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_instance_types" {
  description = "EC2 instance types for node group"
  type        = list(string)
  default     = ["m5.xlarge"]
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in node group"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in node group"
  type        = number
  default     = 10
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in node group"
  type        = number
  default     = 3
}

variable "application_namespace" {
  description = "Kubernetes namespace for application"
  type        = string
  default     = "applications"
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}
EOF
```

### Step 4: Create Helm Chart

Create the Helm chart structure:

```bash
mkdir -p helm/templates helm/values
cat > helm/Chart.yaml << 'EOF'
apiVersion: v2
name: web-application
description: A Helm chart for deploying a web application on Kubernetes
type: application
version: 1.0.0
appVersion: "1.0.0"
keywords:
  - helm
  - kubernetes
  - web application
maintainers:
  - name: DevOps Team
    email: devops@example.com
EOF
```

### Step 5: Create Deployment Template

Create `helm/templates/deployment.yaml`:

```bash
cat > helm/templates/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-{{ .Chart.Name }}
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Chart.Name }}
    version: {{ .Values.image.tag | default .Chart.AppVersion }}
    environment: {{ .Values.environment }}
spec:
  replicas: {{ .Values.replicas }}
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
        version: {{ .Values.image.tag | default .Chart.AppVersion }}
    spec:
      serviceAccountName: {{ .Chart.Name }}-sa
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: {{ .Values.service.targetPort }}
          protocol: TCP
        - name: metrics
          containerPort: 9090
          protocol: TCP
        livenessProbe:
          httpGet:
            path: {{ .Values.livenessProbe.path }}
            port: {{ .Values.service.targetPort }}
          initialDelaySeconds: {{ .Values.livenessProbe.initialDelaySeconds }}
          periodSeconds: {{ .Values.livenessProbe.periodSeconds }}
        readinessProbe:
          httpGet:
            path: {{ .Values.readinessProbe.path }}
            port: {{ .Values.service.targetPort }}
          initialDelaySeconds: {{ .Values.readinessProbe.initialDelaySeconds }}
          periodSeconds: {{ .Values.readinessProbe.periodSeconds }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        env:
        - name: ENVIRONMENT
          value: {{ .Values.environment | quote }}
        - name: LOG_LEVEL
          value: {{ .Values.logLevel | quote }}
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: {{ .Chart.Name }}-db-secret
              key: url
        {{- if .Values.externalSecrets.enabled }}
        - name: SECRET_API_KEY
          valueFrom:
            secretKeyRef:
              name: {{ .Chart.Name }}-app-secret
              key: api-key
        {{- end }}
        volumeMounts:
        - name: config
          mountPath: /config
          readOnly: true
      volumes:
      - name: config
        configMap:
          name: {{ .Chart.Name }}-config
EOF
```

### Step 6: Create Service Template

Create `helm/templates/service.yaml`:

```bash
cat > helm/templates/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-{{ .Chart.Name }}
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Chart.Name }}
    environment: {{ .Values.environment }}
spec:
  type: {{ .Values.service.type }}
  ports:
  - port: {{ .Values.service.port }}
    targetPort: {{ .Values.service.targetPort }}
    protocol: TCP
    name: http
  - port: 9090
    targetPort: 9090
    protocol: TCP
    name: metrics
  selector:
    app: {{ .Chart.Name }}
EOF
```

### Step 7: Create ConfigMap Template

Create `helm/templates/configmap.yaml`:

```bash
cat > helm/templates/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Chart.Name }}-config
  namespace: {{ .Release.Namespace }}
data:
  app.yaml: |
    server:
      port: {{ .Values.service.targetPort }}
      timeout: {{ .Values.config.serverTimeout }}
    logging:
      level: {{ .Values.logLevel }}
      format: json
    features:
      metrics: {{ .Values.features.metrics | default true }}
      tracing: {{ .Values.features.tracing | default true }}
EOF
```

### Step 8: Create Ingress Template

Create `helm/templates/ingress.yaml`:

```bash
cat > helm/templates/ingress.yaml << 'EOF'
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Chart.Name }}-ingress
  namespace: {{ .Release.Namespace }}
  annotations:
    kubernetes.io/ingress.class: {{ .Values.ingress.className }}
    {{- if .Values.ingress.tls.enabled }}
    kubernetes.io/tls-acme: "true"
    {{- end }}
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"
spec:
  {{- if .Values.ingress.tls.enabled }}
  tls:
  - hosts:
    - {{ .Values.ingress.host }}
    secretName: {{ .Chart.Name }}-tls
  {{- end }}
  rules:
  - host: {{ .Values.ingress.host | quote }}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: {{ .Release.Name }}-{{ .Chart.Name }}
            port:
              number: {{ .Values.service.port }}
{{- end }}
EOF
```

### Step 9: Create ServiceAccount Template

Create `helm/templates/serviceaccount.yaml`:

```bash
cat > helm/templates/serviceaccount.yaml << 'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ .Chart.Name }}-sa
  namespace: {{ .Release.Namespace }}
  annotations:
    {{- if .Values.serviceAccount.irsa.enabled }}
    eks.amazonaws.com/role-arn: {{ .Values.serviceAccount.irsa.roleArn }}
    {{- end }}
EOF
```

### Step 10: Create HPA Template

Create `helm/templates/hpa.yaml`:

```bash
cat > helm/templates/hpa.yaml << 'EOF'
{{- if .Values.autoscaling.enabled -}}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .Chart.Name }}-hpa
  namespace: {{ .Release.Namespace }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .Release.Name }}-{{ .Chart.Name }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
  {{- if .Values.autoscaling.targetCPUUtilizationPercentage }}
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
  {{- end }}
  {{- if .Values.autoscaling.targetMemoryUtilizationPercentage }}
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: {{ .Values.autoscaling.targetMemoryUtilizationPercentage }}
  {{- end }}
{{- end }}
EOF
```

### Step 11: Create Values Files

Create `helm/values.yaml`:

```bash
cat > helm/values.yaml << 'EOF'
replicas: 3

environment: development

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.25-alpine"

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

ingress:
  enabled: true
  className: nginx
  host: app.example.com
  tls:
    enabled: true

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

livenessProbe:
  path: /healthz
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  path: /ready
  initialDelaySeconds: 5
  periodSeconds: 5

podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault

config:
  serverTimeout: 30

logLevel: info

features:
  metrics: true
  tracing: true

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

serviceAccount:
  irsa:
    enabled: false
    roleArn: ""

externalSecrets:
  enabled: false
EOF
```

### Step 12: Create Environment-Specific Values

Create `helm/values-prod.yaml`:

```bash
cat > helm/values-prod.yaml << 'EOF'
replicas: 5

environment: production

resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 2000m
    memory: 2Gi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 60

logLevel: warn

service:
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"

ingress:
  host: app-prod.example.com

serviceAccount:
  irsa:
    enabled: true
    roleArn: "arn:aws:iam::123456789012:role/prod-app-role"

externalSecrets:
  enabled: true
EOF
```

### Step 13: Create Makefile

Create a `Makefile` for automation:

```bash
cat > Makefile << 'EOF'
.PHONY: help plan apply destroy deploy test rollback clean

TERRAFORM_DIR := terraform
HELM_DIR := helm
NAMESPACE ?= applications
ENVIRONMENT ?= dev
KUBECONFIG ?= ~/.kube/config

AWS_REGION ?= us-east-1
CLUSTER_NAME ?= helm-terraform-cluster

help:
	@echo "Available targets:"
	@echo "  plan       - Run Terraform plan"
	@echo "  apply      - Apply Terraform configuration"
	@echo "  destroy    - Destroy Terraform resources"
	@echo "  deploy     - Deploy Helm chart"
	@echo "  test       - Test Helm deployment"
	@echo "  rollback   - Rollback Helm release"
	@echo "  clean      - Clean up local files"

plan:
	@echo "Running Terraform plan for $(ENVIRONMENT)..."
	cd $(TERRAFORM_DIR) && \
		terraform init && \
		terraform plan \
			-var="environment=$(ENVIRONMENT)" \
			-var="region=$(AWS_REGION)" \
			-var="cluster_name=$(CLUSTER_NAME)"

apply:
	@echo "Applying Terraform configuration..."
	cd $(TERRAFORM_DIR) && \
		terraform init && \
		terraform apply \
			-var="environment=$(ENVIRONMENT)" \
			-var="region=$(AWS_REGION)" \
			-var="cluster_name=$(CLUSTER_NAME)" \
			-auto-approve

destroy:
	@echo "Destroying Terraform resources..."
	cd $(TERRAFORM_DIR) && \
		terraform destroy \
			-var="environment=$(ENVIRONMENT)" \
			-var="region=$(AWS_REGION)" \
			-var="cluster_name=$(CLUSTER_NAME)" \
			-auto-approve

deploy:
	@echo "Deploying Helm chart to $(NAMESPACE)..."
	helm upgrade --install webapp $(HELM_DIR) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--values $(HELM_DIR)/values-$(ENVIRONMENT).yaml \
		--wait \
		--timeout 5m \
		--debug

test:
	@echo "Testing Helm deployment..."
	helm test webapp --namespace $(NAMESPACE)

rollback:
	@echo "Rolling back Helm release..."
	helm rollback webapp --namespace $(NAMESPACE)

status:
	@echo "Checking Helm release status..."
	helm status webapp --namespace $(NAMESPACE)

list:
	@echo "Listing Helm releases..."
	helm list --namespace $(NAMESPACE) -a

values:
	@echo "Showing Helm values..."
	helm get values webapp --namespace $(NAMESPACE) -a

clean:
	@echo "Cleaning up local files..."
	rm -rf $(TERRAFORM_DIR)/.terraform
	rm -f $(TERRAFORM_DIR)/.terraform.lock.hcl
	find . -name "*.tfplan" -delete
	find . -name ".terraform*" -type d -exec rm -rf {} + 2>/dev/null || true
EOF
```

## Verify

### Verify Infrastructure

```bash
# Check EKS cluster status
aws eks describe-cluster --name helm-terraform-cluster --region us-east-1

# Verify nodes are ready
kubectl get nodes -o wide

# Check namespace was created
kubectl get namespace applications
```

### Verify Helm Deployment

```bash
# List Helm releases
helm list -n applications -a

# Check deployment status
kubectl get deployments -n applications

# Check pods are running
kubectl get pods -n applications

# Check services
kubectl get svc -n applications

# Check ingress
kubectl get ingress -n applications

# View Helm release history
helm history webapp -n applications

# Check pod logs
kubectl logs -n applications -l app=web-application --tail=100
```

### Verify Application

```bash
# Test health endpoint
kubectl exec -n applications deploy/web-application -- curl -s http://localhost:8080/healthz

# Test metrics endpoint
kubectl exec -n applications deploy/web-application -- curl -s http://localhost:9090/metrics | head -20

# Check HPA status
kubectl get hpa -n applications
```

## Rollback

### Rollback Terraform

```bash
# List Terraform state versions
terraform state list

# Restore previous state
terraform state pull > previous.tfstate

# Or use Terraform Cloud/Enterprise for state history
```

### Rollback Helm

```bash
# List release history
helm history webapp -n applications

# Rollback to previous revision
helm rollback webapp 1 -n applications

# Rollback to specific revision
helm rollback webapp 3 -n applications
```

## Common Errors

### Error: "No Kubernetes cluster found"

**Cause**: kubectl not configured to access EKS cluster.

**Resolution**:
```bash
aws eks update-kubeconfig --name helm-terraform-cluster --region us-east-1
```

### Error: "helm upgrade missing required providers"

**Cause**: Helm provider not configured in Terraform.

**Resolution**:
```hcl
# Add to terraform/helm-provider.tf
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
```

### Error: "Unable to recognize input: no matches for kind"

**Cause**: CRD not installed or wrong apiVersion.

**Resolution**:
```bash
# Install required CRDs
kubectl apply -f https://raw.githubusercontent.com/aws/eks-charts/master/stable/aws-load-balancer-controller/crds/crds.yaml

# Check apiVersion in manifest
kubectl api-resources
```

### Error: "InvalidImageName" when pulling Helm chart

**Cause**: Image not found or typo in repository URL.

**Resolution**:
```bash
# Verify image exists
helm search repo <chart-name>

# Update repositories
helm repo update

# Use specific version
helm upgrade --install app chart --version 1.0.0
```

## References

- Terraform EKS Module Documentation — https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
- Helm Chart Best Practices — https://helm.sh/docs/chart_best_practices/
- AWS EKS Best Practices — https://aws.github.io/aws-eks-best-practices/
- Kubernetes Ingress NGINX — https://kubernetes.github.io/ingress-nginx/
- Helmfile for Environment Management — https://github.com/roboll/helmfile

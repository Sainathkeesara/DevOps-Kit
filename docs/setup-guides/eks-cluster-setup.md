# EKS Cluster Setup from Scratch on AWS

## Purpose

This guide provides step-by-step instructions for creating a production-ready Amazon EKS cluster on AWS from scratch. It covers infrastructure setup, cluster creation, worker node configuration, and essential post-deployment verification.

## When to use

Use this guide when:
- Setting up a new EKS cluster for development, staging, or production
- Creating a cluster with proper networking (VPC, subnets)
- Configuring worker nodes with appropriate instance types
- Setting up kubectl access and cluster authentication
- Needing repeatable, documented cluster deployment

## Prerequisites

### Required Tools
- AWS CLI v2.x installed and configured
- `kubectl` installed (version compatible with your EKS cluster version)
- `eksctl` installed (recommended for cluster creation)
- Valid AWS account with appropriate IAM permissions

### IAM Permissions Required
The user creating the cluster needs these IAM permissions:
- `ec2:*` (VPC, security groups, ENIs)
- `eks:*` (cluster, nodegroup, Fargate)
- `iam:*` (roles, policies, OpenID Connect)
- `ecr:*` (container registry access)

### AWS Resource Quotas
Ensure your AWS account has sufficient quotas for:
- VPCs (minimum 1)
- Elastic IPs (minimum 3 for public subnets)
- EC2 instances (for node groups)
- VPC peering (if needed)

## Steps

### 1. Configure AWS CLI

```bash
aws configure
aws configure set region <your-region>
```

Verify configuration:
```bash
aws sts get-caller-identity
```

### 2. Create Cluster with eksctl

Basic cluster creation:
```bash
eksctl create cluster \
  --name my-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 4
```

Cluster with custom VPC:
```bash
eksctl create cluster \
  --name my-cluster \
  --region us-east-1 \
  --vpc-cidr 10.0.0.0/16 \
  --vpc-nat-mode Highly \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 4 \
  --ssh-access \
  --ssh-public-key ~/.ssh/id_rsa.pub
```

Production cluster with additional options:
```bash
eksctl create cluster \
  --name prod-cluster \
  --region us-east-1 \
  --version 1.29 \
  --vpc-cidr 10.0.0.0/16 \
  --vpc-nat-mode Highly \
  --zones us-east-1a,us-east-1b,us-east-1c \
  --nodegroup-name primary-nodes \
  --node-type t3.large \
  --nodes 3 \
  --nodes-min 3 \
  --nodes-max 6 \
  --ssh-access \
  --ssh-public-key ~/.ssh/id_rsa.pub \
  --iam-instance-profile-role arn:aws:iam::123456789:role/EKSS3ReadOnly \
  --asg-access \
  --external-dns-access \
  --full-ecr-access \
  --appmesh-access \
  --appmesh-preview-access
```

### 3. Verify Cluster Access

Test kubectl connectivity:
```bash
kubectl cluster-info
kubectl get nodes
```

### 4. Configure IAM Role for Cluster Access

For IAM role-based access (recommended over AWS root):

```bash
aws eks describe-cluster --name my-cluster --query "cluster.oidc.issuer" --output text
```

Create IAM role for cluster admin:
```bash
aws iam create-role \
  --role-name EKSAdminRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::123456789:root"},
      "Action": "sts:AssumeRole"
    }]
  }'
```

Attach EKS policy:
```bash
aws iam attach-role-policy \
  --role-name EKSAdminRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
```

### 5. Add Node Groups

Create additional node group:
```bash
eksctl create nodegroup \
  --cluster my-cluster \
  --region us-east-1 \
  --name compute-nodes \
  --node-type t3.xlarge \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 5 \
  --ssh-access \
  --ssh-public-key ~/.ssh/id_rsa.pub
```

### 6. Install Add-ons

Core add-ons:
```bash
# CoreDNS
eksctl get addon --cluster my-cluster
eksctl create addon --name coredns --cluster my-cluster

# kube-proxy
eksctl create addon --name kube-proxy --cluster my-cluster

# VPC CNI
eksctl create addon --name vpc-cni --cluster my-cluster
```

### 7. Configure Storage (Optional)

Create StorageClass for EBS:
```bash
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF
```

### 8. Set Up Cluster Autoscaler

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
```

Edit the deployment to set your cluster name:
```bash
kubectl -n kube-system edit deployment cluster-autoscaler
# Set --cluster-name=my-cluster in the container args
```

## Verify

### Cluster Health
```bash
# Check cluster status
aws eks describe-cluster --name my-cluster --query "cluster.status"

# Verify nodes are ready
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system
```

### CoreDNS Verification
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

### Node Group Status
```bash
eksctl get nodegroup --cluster my-cluster
```

### Network Connectivity
```bash
# Test pod-to-pod communication
kubectl run test --image=busybox --rm -it --restart=Never -- sh
# Inside container: ping <another-pod-ip>

# Test service discovery
kubectl run dns-test --image=busybox --rm -it --restart=Never -- nslookup kubernetes
```

### Access Verification
```bash
# Verify AWS IAM authenticator works
aws eks describe-cluster --name my-cluster

# List current context
kubectl config current-context

# Check auth configmap
kubectl get configmap aws-auth -n kube-system -o yaml
```

## Rollback

### Delete Cluster
```bash
eksctl delete cluster --name my-cluster --region us-east-1
```

This removes:
- EKS cluster
- Node groups
- Created security groups
- Auto-created VPC (if not existing)

### Delete Node Group Only
```bash
eksctl delete nodegroup --cluster my-cluster --name compute-nodes
```

### Preserve VPC on Delete
When creating cluster:
```bash
eksctl create cluster --name my-cluster --vpc-id existing-vpc-id ...
```

Delete cluster without removing VPC:
```bash
eksctl delete cluster --name my-cluster --disable-boto-cache
```

## Common Errors

### "Unable to connect to cluster"

Check kubeconfig:
```bash
aws eks update-kubeconfig --name my-cluster --region us-east-1
```

Verify IAM permissions for the role/user.

### "Node group creation failed - ResourceLimitExceeded"

Check AWS quotas:
```bash
aws ec2 describe-account-attributes --attribute-names VPC-max-security-groups-per-interface
aws service-quotas list-service-quotas --service-code ec2
```

Request quota increase or reduce node count.

### "Unauthorized - IAM role not authorized"

Check aws-auth ConfigMap:
```bash
kubectl get configmap aws-auth -n kube-system -o yaml
```

Add IAM role to mapRoles:
```bash
kubectl edit configmap aws-auth -n kube-system
# Add to mapRoles:
# - rolearn: arn:aws:iam::123456789:role/EKSAdminRole
#   username: admin
#   groups:
#   - system:masters
```

### "VPC CNI plugin failed to allocate IP"

Check VPC CNI pod:
```bash
kubectl get pods -n kube-system -l k8s-app=aws-node
kubectl logs -n kube-system -l k8s-app=aws-node
```

Verify ENI capacity:
```bash
aws ec2 describe-network-interface-attribute --attribute eniCapacity
```

### "Cluster timeout during creation"

Check CloudFormation stack:
```bash
aws cloudformation describe-stacks --stack-name eksctl-my-cluster --region us-east-1
```

Delete and retry:
```bash
eksctl delete cluster --name my-cluster
eksctl create cluster --timeout 45m ...
```

## References

- eksctl official documentation: https://eksctl.io/ (verified: 2026-03-10)
- EKS user guide: https://docs.aws.amazon.com/eks/ (verified: 2026-03-10)
- AWS IAM roles for EKS: https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html (verified: 2026-03-10)
- EKS best practices: https://aws.github.io/aws-eks-best-practices/ (verified: 2026-03-10)
- kubectl installation: https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html (verified: 2026-03-10)

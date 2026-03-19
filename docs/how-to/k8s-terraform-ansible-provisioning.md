# Kubernetes Cluster Provisioning with Terraform and Ansible

## Purpose

Provision a production-ready Kubernetes cluster on AWS using Terraform for infrastructure and Ansible for configuration management. Terraform handles VPC networking, EC2 instances, security groups, and load balancers. Ansible installs container runtime, kubeadm, kubelet, and kubectl on all nodes, then initializes the control plane and joins worker nodes.

## When to use

- Initial cluster deployment when you need full control over the infrastructure (not using EKS/GKE)
- Learning the internals of how a Kubernetes cluster is bootstrapped
- Multi-cloud or on-premises Kubernetes deployments following the same pattern
- Reproducible cluster provisioning with version-controlled infrastructure code

## Prerequisites

### Tools required

| Tool | Minimum version | Purpose |
|------|----------------|---------|
| Terraform | 1.5+ | Provision AWS infrastructure |
| Ansible | 2.15+ | Configure nodes and bootstrap cluster |
| AWS CLI | 2.x | Authenticate to AWS |
| kubectl | 1.28+ | Interact with the cluster |
| SSH client | any | Access nodes via bastion |

### AWS IAM permissions

The AWS credentials used must allow:
- `ec2:RunInstances`, `ec2:TerminateInstances`
- `ec2:CreateSecurityGroup`, `ec2:AuthorizeSecurityGroupIngress`
- `ec2:Describe*`
- `elasticloadbalancing:*`
- `iam:CreateInstanceProfile`, `iam:PassRole`

### Network requirements

- Outbound internet access from all subnets (NAT gateway or direct)
- Inbound: TCP 22 (bastion), TCP 6443 (kube-apiserver via LB)
- Ubuntu 22.04 LTS (AMI: `ami-05540a4c4c13eff20` in `us-east-1`, change for other regions)

## Steps

### 1. Clone the repository and navigate to Terraform

```bash
git clone https://github.com/your-org/devops-kit.git
cd devops-kit/docs/how-to/k8s-terraform-ansible-provisioning/terraform
```

### 2. Configure AWS credentials

```bash
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"
```

Or use `aws configure` for named profile.

### 3. Customize variables

Edit `variables.tf` or create `terraform.tfvars`:

```bash
# terraform.tfvars
cluster_name      = "prod-k8s"
aws_region        = "us-east-1"
vpc_cidr          = "10.0.0.0/16"
availability_zone = "us-east-1a"

# Control plane
cp_instance_type  = "t3.medium"
cp_instance_count = 3

# Workers
worker_instance_type = "t3.large"
worker_instance_count = 3

# SSH key — create or import in AWS first
ssh_key_name = "k8s-provisioning-key"
```

### 4. Create the SSH key pair (if needed)

```bash
ssh-keygen -t ed25519 -f ~/.ssh/k8s-provisioning-key -N ""
aws ec2 import-key-pair \
  --key-name k8s-provisioning-key \
  --public-key-material file://~/.ssh/k8s-provisioning-key.pub
```

### 5. Initialize Terraform

```bash
terraform init
```

### 6. Plan and review

```bash
terraform plan -out=tfplan
```

Expected output: ~40 resources (VPC, subnets, route tables, IGW, NAT GW, security groups, EC2 instances, IAM roles, target group, NLB).

### 7. Apply infrastructure

```bash
terraform apply tfplan
```

Expected duration: 3–5 minutes. The apply outputs the bastion IP and a dynamically generated Ansible inventory.

### 8. Note the outputs

```bash
terraform output
```

Save these values:
- `bastion_public_ip` — connect through this to reach control plane nodes
- `control_plane_private_ips` — comma-separated private IPs of control plane nodes
- `worker_private_ips` — comma-separated private IPs of worker nodes
- `kubeconfig_b64` — base64-encoded kubeconfig for the cluster

### 9. Configure the Ansible inventory

Terraform outputs a ready-to-use `inventory.ini`. Copy it from the terraform directory:

```bash
cp ../ansible/inventory.ini.example ../ansible/inventory.ini
# Edit ../ansible/inventory.ini and fill in:
# - ansible_host for each node (use bastion as jump host)
# - ansible_user = ubuntu
# - ansible_ssh_private_key_file = ~/.ssh/k8s-provisioning-key
```

If Terraform was used, it generates the inventory automatically. Verify:

```bash
cd ../ansible
grep -c "\[kube_control_plane\]" inventory.ini   # should be 3
grep -c "\[kube_workers\]" inventory.ini         # should be 3
```

### 10. Test Ansible connectivity

```bash
cd ../ansible
ansible all -i inventory.ini -m ping
```

All nodes should return `pong`. If connectivity fails, check:
- SSH key permissions: `chmod 600 ~/.ssh/k8s-provisioning-key`
- Bastion is reachable: `ssh -i ~/.ssh/k8s-provisioning-key ubuntu@<bastion-ip>`
- Security groups allow port 22 from your IP

### 11. Run the Ansible playbook

```bash
ansible-playbook -i inventory.ini site.yml
```

The playbook runs in stages:

**Stage 1 — Preflight** (`preflight.yml`):
- Updates apt cache and upgrades packages
- Installs `python3`, `jq`, `curl`, `wget`, `gnupg`, `lsb-release`
- Configures `/etc/hosts` with short names
- Sets kernel modules (`br_netfilter`, `overlay`) and sysctl params

**Stage 2 — Container runtime** (`container-runtime.yml`, included in site.yml):
- Installs containerd from Docker repository
- Configures containerd `config.toml` with systemd cgroup driver
- Enables and starts containerd

**Stage 3 — Kubernetes components** (`kubernetes.yml`, included in site.yml):
- Adds Kubernetes apt repository and installs `kubelet`, `kubeadm`, `kubectl`
- Holds packages at current version (`apt-mark hold`)
- Enables and starts kubelet (kubelet will error until join — this is expected)

**Stage 4 — Bootstrap control plane** (`bootstrap-control-plane.yml`, included in site.yml):
- Runs `kubeadm init` on the first control plane node
- Copies admin kubeconfig to `$HOME/.kube/config`
- Installs Calico CNI via `kubectl apply`
- Waits for API server to be ready
- Generates and saves the join command for workers

**Stage 5 — Join workers** (`join-workers.yml`, included in site.yml):
- Copies the join command from the control plane bootstrap
- Runs `kubeadm join` on all worker nodes

Expected duration: 15–25 minutes end-to-end.

### 12. Verify the cluster

From the bastion host (or any machine with kubeconfig):

```bash
kubectl get nodes
```

Expected output:
```
NAME            STATUS   ROLES           AGE
cp-1            Ready    control-plane   5m
cp-2            Ready    control-plane   5m
cp-3            Ready    control-plane   5m
worker-1        Ready    <none>          3m
worker-2        Ready    <none>          3m
worker-3        Ready    <none>          3m
```

All nodes should be `Ready`. If nodes are `NotReady`, check:
```bash
kubectl describe node <node-name> | grep -A 10 "Conditions"
```

### 13. Deploy a test workload

```bash
kubectl run nginx --image=nginx:1.25 --expose --port=80
kubectl get pods -l run=nginx
kubectl logs deployment/nginx
```

### 14. Decode the kubeconfig (if Terraform output was used)

```bash
terraform output kubeconfig_b64 | base64 -d > ~/.kube/config
kubectl config use-context k8s-prod
kubectl get nodes
```

## Verify

1. **Infrastructure**: `terraform show` — all resources created and tagged
2. **Nodes reachable**: `ansible all -i inventory.ini -m shell -a "hostname"` — all nodes respond
3. **Cluster formed**: `kubectl get nodes` — all nodes Ready, roles correct
4. **CNI active**: `kubectl get pods -n kube-system` — Calico pods Running
5. **API server responsive**: `kubectl get --raw /healthz` — returns `ok`
6. **No stuck pods**: `kubectl get pods -A | grep -v Running | grep -v Completed` — empty

## Rollback

### Tear down the cluster (Ansible)

```bash
cd ../ansible
ansible-playbook -i inventory.ini teardown.yml
# OR manually on each node:
# sudo kubeadm reset --force
# sudo apt-get purge -y kubeadm kubelet kubectl
# sudo rm -rf /etc/kubernetes/manifests /var/lib/etcd
```

### Destroy infrastructure (Terraform)

```bash
cd ../terraform
terraform destroy
# Confirm: type yes
```

Expected duration: 2–4 minutes.

## Common errors

### "Unable to connect to the server: dial tcp: i/o timeout"

The kubectl machine cannot reach the API server. If using a bastion:
- Ensure your kubeconfig points to the NLB DNS name, not an internal IP
- Check that the NLB security group allows your IP on TCP 6443
- Verify the target group health checks pass: AWS Console → EC2 → Target Groups → `k8s-api-tg`

### "kubeadm init: error uploading crisocket"

The first kubeadm init is still running when subsequent tasks try to talk to the API server. The playbook includes a 60-second wait. If it still fails:
```bash
# Manually check kubelet on cp-1
ssh -i ~/.ssh/k8s-provisioning-key ubuntu@<cp-1-private-ip>
sudo systemctl status kubelet
sudo journalctl -u kubelet -n 50 --no-pager
```

### "ansible-playbook: host unreachable"

SSH connectivity through the bastion failed. Set up SSH agent forwarding:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/k8s-provisioning-key
# Add to ~/.ssh/config:
# Host cp-*
#   ProxyJump ubuntu@<bastion-ip>
#   IdentityFile ~/.ssh/k8s-provisioning-key
```

### "containerd: failed to set sandbox image"

Common on Ubuntu 22.04 with containerd 1.6+. The playbook sets `sandbox_image` in containerd config:
```bash
grep sandbox_image /etc/containerd/config.toml
# Should be: sandbox_image = "registry.k8s.io/pause:3.9"
```

### "Calico pods CrashLoopBackOff"

Usually a CNI CIDR conflict. Check Calico's felix configuration:
```bash
kubectl get configmap -n kube-system calico-config -o yaml | grep CALICO_IPV4POOL_CIDR
# Ensure it doesn't overlap with VPC CIDR or node pod CIDRs
```

### "terraform apply: Error creating IAM instance profile"

The IAM role already exists from a prior run. The playbook handles this with `terraform apply` idempotency. If blocked:
```bash
aws iam delete-instance-profile --instance-profile-name k8s-nodes-profile
terraform apply
```

## References

- [kubeadm installation guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [kubeadm control plane bootstrap](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
- [Calico CNI installation](https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-on-prem/installation)
- [Ansible kubeadm module](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/kubeadm_module.html)
- [Terraform AWS provider EC2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [AWS EKS Best Practices — Networking](https://aws.github.io/aws-eks-best-practices/networking/)

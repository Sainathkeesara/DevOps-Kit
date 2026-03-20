# Kubernetes GitOps Workflow with ArgoCD and Vault Secrets Injection

## Purpose

Implement a complete GitOps workflow using ArgoCD for declarative Kubernetes deployments with HashiCorp Vault for secrets management. This walkthrough covers installing ArgoCD, configuring GitOps repositories, setting up Vault's Kubernetes auth method, and injecting secrets into applications through the Vault CSI Provider.

## When to use

- Deploying applications to Kubernetes using Git as the single source of truth
- Managing sensitive information (API keys, passwords, TLS certificates) securely in GitOps workflows
- Implementing secrets rotation without application downtime
- Achieving compliance with GitOps audit requirements
- Multi-environment deployments (dev/staging/prod) with separate secret stores

## Prerequisites

### Tools required

| Tool | Minimum version | Purpose |
|------|----------------|---------|
| Kubernetes | 1.24+ | Cluster to deploy to |
| Helm | 3.10+ | Install ArgoCD and Vault |
| kubectl | 1.24+ | Interact with cluster |
| Vault | 1.14+ | Secrets management |
| ArgoCD | 2.8+ | GitOps controller |
| Vault CSI Provider | 1.4+ | Secrets injection |

### Cluster requirements

- Kubernetes cluster with at least 3 nodes
- StorageClass for persistent volumes (default or specific)
- Minimum 4GB RAM available per node
- Network access to Git repositories (GitHub/GitLab/Bitbucket)

### External dependencies

- HashiCorp Vault cluster (can be self-hosted or HCP Vault)
- Git repository for GitOps configuration
- Container registry access (Docker Hub, GHCR, ECR, etc.)

## Steps

### 1. Install ArgoCD to the cluster

```bash
# Create namespace for ArgoCD
kubectl create namespace argocd

# Install ArgoCD using manifests
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Or install using Helm
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd -n argocd --create-namespace

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 2. Access the ArgoCD UI

```bash
# Port-forward to access UI (for local development)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Or expose via LoadBalancer
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"LoadBalancer"}}'

# Access UI at https://localhost:8080 or via LoadBalancer DNS
# Username: admin
# Password: <from step 1>
```

### 3. Configure Git repository for GitOps

```bash
# Create a GitHub repository for GitOps configuration
# Clone it locally
git clone https://github.com/your-org/k8s-gitops.git
cd k8s-gitops

# Create directory structure
mkdir -p apps base/environments/{dev,staging,prod}
mkdir -p base/applications
mkdir -p components/{nginx,redis,secrets}

# Initialize git
git init
git add .
git commit -m "Initial GitOps structure"
git branch -M master
git remote add origin https://github.com/your-org/k8s-gitops.git
git push -u origin master
```

### 4. Add Git repository to ArgoCD

```bash
# Using argocd CLI (install if needed)
brew install argocd

# Login to ArgoCD
argocd login localhost:8080 --username admin --password <password>

# Add Git repository
argocd repo add https://github.com/your-org/k8s-gitops.git --type git --name your-org

# Or add via UI: Settings -> Repositories -> Connect Repo
```

### 5. Install Vault and configure Kubernetes auth

```bash
# Create namespace for Vault
kubectl create namespace vault

# Add HashiCorp Helm repository
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Install Vault with Kubernetes auth enabled
helm install vault hashicorp/vault \
  -n vault \
  --set "server.dev.enabled=true" \
  --set "injector.enabled=true" \
  --create-namespace

# For production, use standalone or cluster mode with TLS
```

### 6. Configure Vault Kubernetes authentication

```bash
# Exec into Vault pod
kubectl exec -it vault-0 -n vault -- sh

# Enable Kubernetes auth method
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    issuer="kubernetes/serviceaccount"

# Create policy for secret reading
vault policy write k8s-secrets - <<EOF
path "secret/data/k8s/*" {
  capabilities = ["read"]
}
EOF

# Create Kubernetes service account for Vault
kubectl create serviceaccount vault-auth -n vault

# Create Vault auth role
vault write auth/kubernetes/role/k8s-secrets \
    bound_service_account_names=vault-auth \
    bound_service_account_namespaces=default \
    policies=k8s-secrets \
    ttl=1h
```

### 7. Store secrets in Vault

```bash
# Enable KV v2 secrets engine
vault secrets enable -path=secret kv-v2

# Store database credentials
vault kv put secret/k8s/myapp/database \
    username="appuser" \
    password="super-secret-password" \
    host="postgres.default.svc" \
    port="5432"

# Store API keys
vault kv put secret/k8s/myapp/api-keys \
    stripe_key="sk_live_xxxxx" \
    sendgrid_key="SG.xxxxx"

# Store TLS certificates
vault kv put secret/k8s/myapp/tls \
    certificate="$(cat server.crt)" \
    private_key="$(cat server.key)"

# Verify secrets
vault kv list secret/k8s/myapp/
vault kv get secret/k8s/myapp/database
```

### 8. Install Vault CSI Provider

```bash
# Install Vault CSI Provider
kubectl apply -f https://raw.githubusercontent.com/hashicorp/vault-csi-provider/main/deployment/vault-csi-provider.yaml

# Or via Helm
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault-csi hashicorp/vault-csi-provider -n vault-secrets

# Verify installation
kubectl get pods -n vault-secrets -l app.kubernetes.io/name=vault-csi-provider
```

### 9. Create Kubernetes SecretStore

```bash
# Create SecretStore for Vault provider
cat <<EOF | kubectl apply -f -
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: default
spec:
  provider:
    vault:
      address: "http://vault.vault.svc:8200"
      auth:
        kubernetes:
          mountPath: kubernetes
          role: k8s-secrets
EOF
```

### 10. Create sample application manifests

```bash
# Create application directory structure in GitOps repo
mkdir -p apps/myapp/base
mkdir -p apps/myapp/overlays/{dev,staging,prod}

# Create base deployment
cat > apps/myapp/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: nginx:1.25
        ports:
        - containerPort: 80
        env:
        - name: DATABASE_HOST
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: host
        - name: DATABASE_USER
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: username
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: password
EOF

# Create service
cat > apps/myapp/base/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
```

### 11. Create SecretProviderClass for secrets injection

```bash
# Create SecretProviderClass
cat > apps/myapp/base/secret-provider.yaml <<'EOF'
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: myapp-secrets
spec:
  provider: vault
  secretObjects:
  - secretName: myapp-secrets
    type: Opaque
    data:
    - objectName: database
      key: db-creds
      env:
        - envVar: DATABASE_CREDS
          containerName: myapp
  parameters:
    roleName: "k8s-secrets"
    vaultAddress: "http://vault.vault.svc:8200"
    objects: |
      - objectName: "database"
        secretPath: "secret/data/k8s/myapp/database"
        secretKey: "password"
      - objectName: "api-key"
        secretPath: "secret/data/k8s/myapp/api-keys"
        secretKey: "stripe_key"
EOF
```

### 12. Create ArgoCD Application

```bash
# Create ArgoCD Application manifest
cat > apps/myapp/overlays/dev/application.yaml <<'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp-dev
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/k8s-gitops.git
    targetRevision: master
    path: apps/myapp/overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF

# Create kustomization for dev environment
cat > apps/myapp/overlays/dev/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base/deployment.yaml
- ../../base/service.yaml
- ../../base/secret-provider.yaml

namespace: dev

commonLabels:
  environment: dev
EOF
```

### 13. Commit and push to Git

```bash
# Add all files
git add .
git commit -m "Add myapp with Vault secrets injection"

# Push to remote
git push origin master
```

### 14. Sync application with ArgoCD

```bash
# Using ArgoCD CLI
argocd app sync myapp-dev

# Or from UI:
# Applications -> myapp-dev -> Sync

# Check application status
argocd app get myapp-dev

# Check synced resources
kubectl get all -n dev
```

### 15. Verify secrets injection

```bash
# Check that secrets are mounted
kubectl exec -it deploy/myapp -n dev -- ls /mnt/secrets/

# Verify environment variables are set
kubectl exec -it deploy/myapp -n dev -- env | grep DATABASE

# Check SecretProviderClass status
kubectl get secretproviderclass myapp-secrets -n dev -o yaml

# Check CSI driver logs
kubectl logs -n vault-secrets -l app.kubernetes.io/name=vault-csi-provider
```

## Verify

1. **ArgoCD syncs successfully**: `argocd app list` shows myapp-dev as Healthy and Synced
2. **Application deployed**: `kubectl get pods -n dev` shows running pods
3. **Secrets injected**: `kubectl get secrets myapp-secrets -n dev` exists
4. **Environment variables**: `kubectl exec -it deploy/myapp -n dev -- env | grep DATABASE` shows values
5. **GitOps verified**: Changes to Git repository are automatically reflected in cluster

## Rollback

### Rollback application to previous version

```bash
# Rollback to previous revision
argocd app rollback myapp-dev 1

# Or via UI: Application -> History & Rollback -> Select revision
```

### Remove application and secrets

```bash
# Delete application (will also delete resources if prune is enabled)
argocd app delete myapp-dev

# Or manually
kubectl delete -f apps/myapp/overlays/dev/application.yaml
kubectl delete secret myapp-secrets -n dev
```

### Disable Vault Kubernetes auth

```bash
vault auth disable kubernetes
```

## Common errors

### "Failed to sync: User is not authorized to perform"

Ensure the ArgoCD service account has appropriate RBAC permissions:
```bash
kubectl auth can-i create pods --as=system:serviceaccount:argocd:argocd-application-controller -n dev
```

### "Vault secrets not mounted: error creating client: no vault token"

Check Vault CSI Provider logs:
```bash
kubectl logs -n vault-secrets -l app.kubernetes.io/name=vault-csi-provider --tail=50
```

Verify Kubernetes auth is configured correctly:
```bash
vault auth list
vault read auth/kubernetes/role/k8s-secrets
```

### "Application stuck in Progressing state"

Check ArgoCD controller logs:
```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=50
```

Check resource events:
```bash
kubectl describe application myapp-dev -n argocd
```

### "SecretProviderClass not found"

Ensure SecretProviderClass is in the same namespace as the pod:
```bash
kubectl get secretproviderclass -A
kubectl get secretproviderclass myapp-secrets -n dev
```

### "Vault unreachable from pod"

Check network policies and DNS resolution:
```bash
kubectl exec -it myapp-pod -n dev -- curl -s http://vault.vault.svc:8200/v1/sys/health
```

## References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Vault Kubernetes Authentication](https://developer.hashicorp.com/vault/docs/auth/kubernetes)
- [Vault CSI Provider](https://developer.hashicorp.com/vault/docs/platform/k8s/csi)
- [ArgoCD Application Set](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/)
- [Kustomize](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/)
- [External Secrets Operator](https://external-secrets.io/) (alternative to Vault CSI)

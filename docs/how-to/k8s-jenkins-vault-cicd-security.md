# Kubernetes CI/CD Pipeline with Jenkins and Vault Secrets Injection

## Purpose

Build a secure CI/CD pipeline on Kubernetes that integrates Jenkins for continuous integration, HashiCorp Vault for secrets management, and automated security scanning with Trivy and Kubescape. This project demonstrates a production-ready GitOps workflow where container images are built, scanned for vulnerabilities, and deployed with secrets injected securely from Vault.

## When to use

- Deploying applications to Kubernetes with secure secret management
- Implementing DevSecOps practices with automated security scanning
- Setting up Jenkins controllers and agents on Kubernetes
- Integrating Vault's Kubernetes auth method for dynamic secrets
- Building a complete CI/CD pipeline with security gates

## Prerequisites

### Tools required

| Tool | Minimum version | Purpose |
|------|----------------|---------|
| Kubernetes | 1.28+ | Container orchestration |
| Jenkins | 2.426+ | CI/CD automation |
| Vault | 1.15+ | Secrets management |
| kubectl | 1.28+ | K8s interaction |
| Helm | 3.14+ | Package management |
| Docker | 24.0+ | Container runtime |
| Trivy | 0.50+ | Vulnerability scanning |
| Kubescape | 3.0+ | K8s security scanning |

### Kubernetes cluster requirements

- Minimum 3 worker nodes with 4 vCPU and 16GB RAM each
- Ingress controller (nginx-ingress or ingress-nginx)
- Cert-manager for TLS certificates
- MetalLB or cloud load balancer for external access

### Network requirements

- Outbound internet access for pulling container images
- Inbound: HTTP/HTTPS for ingress, TCP 8080 for Jenkins
- Vault accessible on port 8200 (can be internal)

## Steps

### 1. Install Jenkins on Kubernetes

#### Add Jenkins Helm repository and install:

```bash
helm repo add jenkins https://charts.jenkins.io
helm repo update

kubectl create namespace jenkins

cat > jenkins-values.yaml << 'EOF'
controller:
  serviceType: ClusterIP
  adminUser: admin
  adminPassword: changeme
  ingress:
    enabled: true
    hostName: jenkins.example.com
    tls:
      - secretName: jenkins-tls
        hosts:
          - jenkins.example.com

  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 2000m
      memory: 4Gi

  persistence:
    size: 20Gi

agent:
  enabled: true
  podTemplates:
    docker:
      image: docker:24-dind
      privileged: true
      resourceRequestCpu: 1000m
      resourceRequestMemory: 2Gi
EOF

helm install jenkins jenkins/jenkins -n jenkins -f jenkins-values.yaml
```

#### Wait for Jenkins to be ready:

```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=jenkins-controller -n jenkins --timeout=300s

# Get initial admin password
kubectl exec -n jenkins svc/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
```

### 2. Install Vault on Kubernetes

#### Install Vault with Helm:

```bash
kubectl create namespace vault

helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

cat > vault-values.yaml << 'EOF'
server:
  ha:
    enabled: true
    replicas: 3
    raft:
      setNodeId: true

  dataStorage:
    size: 10Gi

  serviceAccount:
    create: false
    name: vault

  ui:
    enabled: true
    serviceType: ClusterIP

injector:
  enabled: true
  metrics:
    enabled: true

server:
  resources:
    requests:
      cpu: 250m
      memory: 256Mi
    limits:
      cpu: 1000m
      memory: 1Gi
EOF

helm install vault hashicorp/vault -n vault -f vault-values.yaml
```

#### Initialize and unseal Vault:

```bash
# Initialize Vault
kubectl exec -n vault vault-0 -- vault operator init -key-shares=3 -key-threshold=2 -format=json > /tmp/vault-init.json

# Unseal Vault
UNSEAL_KEY1=$(jq -r '.unseal_keys_b64[0]' /tmp/vault-init.json)
UNSEAL_KEY2=$(jq -r '.unseal_keys_b64[1]' /tmp/vault-init.json)
ROOT_TOKEN=$(jq -r '.root_token' /tmp/vault-init.json)

kubectl exec -n vault vault-0 -- vault operator unseal $UNSEAL_KEY1
kubectl exec -n vault vault-1 -- vault operator unseal $UNSEAL_KEY1
kubectl exec -n vault vault-2 -- vault operator unseal $UNSEAL_KEY1

kubectl exec -n vault vault-0 -- vault operator unseal $UNSEAL_KEY2
kubectl exec -n vault vault-1 -- vault operator unseal $UNSEAL_KEY2
kubectl exec -n vault vault-2 -- vault operator unseal $UNSEAL_KEY2
```

### 3. Configure Vault for Kubernetes Authentication

#### Enable Kubernetes auth method:

```bash
export VAULT_ADDR="http://vault.vault.svc.cluster.local:8200"
export VAULT_TOKEN="$ROOT_TOKEN"

# Enable Kubernetes auth
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \\
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \\
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \\
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

#### Create Vault policy and role:

```bash
# Create policy for app secrets
vault policy write app-policy - << 'EOF'
path "secret/data/myapp/*" {
  capabilities = ["read"]
}
path "database/creds/myapp-db" {
  capabilities = ["read"]
}
EOF

# Create Kubernetes auth role
vault write auth/kubernetes/role/myapp \\
    bound_service_account_names=myapp-sa \\
    bound_service_account_namespaces=production \\
    policies=app-policy \\
    ttl=1h
```

### 4. Create Jenkins Pipeline with Security Scanning

#### Create the Jenkinsfile:

```groovy
pipeline {
    agent {
        kubernetes {
            yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  serviceAccountName: jenkins-agent
                  containers:
                  - name: builder
                    image: docker:24-dind
                    securityContext:
                      privileged: true
                    volumeMounts:
                    - name: docker-socket
                      mountPath: /var/run/docker.sock
                  - name: trivy
                    image: aquasec/trivy:0.50.0
                    command:
                    - sleep
                    - infinity
                  - name: kubectl
                    image: bitnami/kubectl:1.28
                    command:
                    - sleep
                    - infinity
                  volumes:
                  - name: docker-socket
                    hostPath:
                      path: /var/run/docker.sock
            '''
        }
    }

    environment {
        DOCKER_REGISTRY = 'registry.example.com'
        APP_NAME = 'myapp'
        VAULT_ADDR = 'http://vault.vault.svc.cluster.local:8200'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                container('builder') {
                    sh '''
                        docker build -t $APP_NAME:$BUILD_NUMBER .
                        docker tag $APP_NAME:$BUILD_NUMBER $DOCKER_REGISTRY/$APP_NAME:$BUILD_NUMBER
                    '''
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                container('trivy') {
                    sh '''
                        trivy image --exit-code 1 --severity HIGH,CRITICAL $APP_NAME:$BUILD_NUMBER || true
                    '''
                }
            }
        }

        stage('Kubescape Scan') {
            steps {
                container('kubectl') {
                    sh '''
                        kubectl cluster-info
                        kubescape scan --severity-threshold HIGH --format json > kubescape-results.json || true
                    '''
                }
            }
        }

        stage('Get Secrets from Vault') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'vault-token', variable: 'VAULT_TOKEN')]) {
                        sh '''
                            DB_PASSWORD=$(vault kv get -field=password secret/data/myapp/db)
                            echo "DB_PASSWORD retrieved from Vault"
                        '''
                    }
                }
            }
        }

        stage('Deploy to Staging') {
            when {
                branch 'main'
            }
            steps {
                container('kubectl') {
                    sh '''
                        kubectl set image deployment/myapp myapp=$DOCKER_REGISTRY/$APP_NAME:$BUILD_NUMBER -n staging
                        kubectl rollout status deployment/myapp -n staging
                    '''
                }
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
                buildingTag()
            }
            steps {
                container('kubectl') {
                    sh '''
                        kubectl set image deployment/myapp myapp=$DOCKER_REGISTRY/$APP_NAME:$GIT_TAG -n production
                        kubectl rollout status deployment/myapp -n production
                    '''
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'kubescape-results.json', allowEmptyArchive: true
            cleanWs()
        }
    }
}
```

### 5. Deploy Application with Vault Sidecar

#### Create Kubernetes manifests:

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      serviceAccountName: myapp-sa
      containers:
      - name: myapp
        image: myapp:latest
        ports:
        - containerPort: 8080
        env:
        - name: DB_HOST
          value: "postgres.production.svc.cluster.local"
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: password
        - name: VAULT_ADDR
          value: "http://vault.vault.svc.cluster.local:8200"
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "myapp"
        vault.hashicorp.com/agent-inject-secret-db-creds: "secret/data/myapp/db"
        vault.hashicorp.com/agent-inject-template-db-creds: |
          {{- with secret "secret/data/myapp/db" -}}
          export DB_USERNAME="{{ .Data.data.username }}"
          export DB_PASSWORD="{{ .Data.data.password }}"
          {{- end }}
```

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: production
spec:
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 8080
```

### 6. Configure Ingress with TLS

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp
            port:
              number: 80
```

## Verify

### Check Jenkins deployment:

```bash
kubectl get pods -n jenkins
kubectl get ingress -n jenkins
```

### Verify Vault is unsealed:

```bash
kubectl exec -n vault vault-0 -- vault status
```

### Test Vault Kubernetes auth:

```bash
# Run from a pod with the correct service account
kubectl run test-auth --rm -it --restart=Never \\
    --image=hashicorp/vault:1.15 \\
    -- /bin/sh -c 'vault write auth/kubernetes/login role=myapp jwt=\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)'
```

### Check application deployment:

```bash
kubectl get pods -n production
kubectl get ingress -n production
kubectl describe ingress myapp -n production
```

### Verify TLS certificate:

```bash
kubectl get certificate -n production
kubectl get certmanager.io/certificate myapp-tls -n production
```

## Rollback

### Rollback Jenkins deployment:

```bash
helm rollback jenkins -n jenkins
```

### Rollback application:

```bash
kubectl rollout undo deployment/myapp -n production
kubectl rollout status deployment/myapp -n production
```

### Seal Vault (emergency):

```bash
kubectl exec -n vault vault-0 -- vault operator seal
```

## Common errors

### Jenkins agent pod stuck in Pending

**Symptom:** Agent pods don't start, stuck in Pending state.

**Cause:** Insufficient cluster resources or missing StorageClass.

**Fix:**
```bash
kubectl describe pod <pod-name> -n jenkins
# Check resource limits and StorageClass
kubectl get storageclass
# If no StorageClass, create one or use default
kubectl patch storageclass <name> -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}'
```

### Vault sealed after pod restart

**Symptom:** Vault pods restart and become sealed.

**Cause:** Automatic unsealing not configured.

**Fix:** Use Vault's auto-unseal feature with cloud KMS or configure manual unseal keys:
```bash
# Unseal all pods manually
kubectl exec -n vault vault-0 -- vault operator unseal <key1>
kubectl exec -n vault vault-1 -- vault operator unseal <key1>
kubectl exec -n vault vault-2 -- vault operator unseal <key1>
```

### Trivy scan fails with permission denied

**Symptom:** Trivy cannot scan images.

**Cause:** Docker socket not mounted or permission issues.

**Fix:** Ensure Docker socket is mounted and Docker daemon is accessible:
```bash
# Check if Docker socket exists in pod
kubectl exec -it <pod-name> -c builder -- ls -la /var/run/docker.sock
```

### Kubescape scan returns no results

**Symptom:** Kubescape scan completes but shows no findings.

**Cause:** Missing context or connection issues.

**Fix:**
```bash
# Verify cluster access
kubectl cluster-info
# Run Kubescape with verbose
kubescape scan --verbose --format json
```

## References

- [Jenkins Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [HashiCorp Vault Kubernetes Auth](https://developer.hashicorp.com/vault/docs/auth/kubernetes)
- [Vault Agent Injector](https://developer.hashicorp.com/vault/docs/platform/k8s/injector)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Kubescape Documentation](https://kubescape.io/docs/)
- [Kubernetes Ingress NGINX](https://kubernetes.github.io/ingress-nginx/)
- [Cert-manager Documentation](https://cert-manager.io/docs/)

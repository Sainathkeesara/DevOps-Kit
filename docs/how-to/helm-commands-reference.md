# Helm CLI Commands Reference

A comprehensive reference for common Helm operations.

## Repository Management

```bash
# Add a Helm repository
helm repo add stable https://charts.helm.sh/stable

# Add a repository with custom name
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update repository cache
helm repo update

# List all added repositories
helm repo list

# Search for charts in all added repos
helm search repo nginx

# Search with specific version
helm search repo redis --version "18.x"

# Remove a repository
helm repo remove stable

# Clean up expired or unused repository cache
helm repo prune
```

## Chart Operations

```bash
# Download a chart without installing
helm pull bitnami/nginx

# Download and untar
helm pull bitnami/nginx --untar

# Pull specific version
helm pull bitnami/nginx --version 15.0.0

# Inspect a chart (values.yaml)
helm show values bitnami/nginx

# Show all chart information
helm show all bitnami/nginx

# Show chart README
helm show readme bitnami/nginx

# Show chart CRDs
helm show crds bitnami/nginx
```

## Installation & Upgrade

```bash
# Install a chart
helm install my-release bitnami/nginx

# Install with custom name
helm install my-nginx bitnami/nginx

# Install with specific version
helm install my-nginx bitnami/nginx --version 15.0.0

# Install with values file
helm install my-nginx bitnami/nginx -f values.yaml

# Install with multiple values files (later takes precedence)
helm install my-nginx bitnami/nginx -f values.yaml -f custom.yaml

# Install with set values
helm install my-nginx bitnami/nginx --set service.type=LoadBalancer

# Install in specific namespace
helm install my-nginx bitnami/nginx --namespace production

# Create namespace if it doesn't exist
helm install my-nginx bitnami/nginx --create-namespace

# Dry-run (preview what would be installed)
helm install my-nginx bitnami/nginx --dry-run --debug

# Upgrade existing release
helm upgrade my-release bitnami/nginx

# Upgrade to specific version
helm upgrade my-release bitnami/nginx --version 15.0.0

# Upgrade with values
helm upgrade my-release bitnami/nginx -f new-values.yaml

# Atomic upgrade (rollback on failure)
helm upgrade my-release bitnami/nginx --atomic

# Install or upgrade (if exists, upgrade; if not, install)
helm upgrade --install my-release bitnami/nginx
```

## Release Management

```bash
# List all releases in a namespace
helm list

# List releases in all namespaces
helm list --all-namespaces

# List with status filter
helm list --filter 'my-.*'

# Get release status
helm status my-release

# Get release values
helm get values my-release

# Get all release info
helm get all my-release

# Get manifest (Kubernetes resources)
helm get manifest my-release

# Get hooks (pre-install hooks, etc.)
helm get hooks my-release

# Rollback to previous revision
helm rollback my-release

# Rollback to specific revision
helm rollback my-release 3

# Rollback with dry-run
helm rollback my-release --dry-run

# Uninstall release
helm uninstall my-release

# Uninstall with keep history
helm uninstall my-release --keep-history

# Uninstall with atomic (rollback on failure)
helm uninstall my-release --atomic
```

## History & Revision

```bash
# List release history
helm history my-release

# Get specific revision
helm get revision my-release --revision 3

# Rollback with options
helm rollback my-release 2 --force
```

## Values & Configuration

```bash
# Show default values
helm show values bitnami/nginx

# Show computed values (after templates)
helm template bitnami/nginx

# Template with values file
helm template bitnami/nginx -f values.yaml

# Template with namespace
helm template bitnami/nginx --namespace myns

# Diff between current and new values
helm diff upgrade my-release bitnami/nginx

# Diff with specific values
helm diff upgrade my-release bitnami/nginx -f values.yaml

# Get computed values
helm get values my-release --all
```

## Plugin Management

```bash
# List installed plugins
helm plugin list

# Install plugin
helm plugin install https://github.com/chartmuseum/helm-push

# Update plugin
helm plugin update

# Uninstall plugin
helm plugin uninstall
```

## Testing & Debugging

```bash
# Lint a chart directory
helm lint ./my-chart

# Lint with strict mode
helm lint ./my-chart --strict

# Template rendering test
helm template my-release ./my-chart

# Template with debug mode
helm template my-release ./my-chart --debug

# Verify chart signature
helm verify ./my-chart-0.1.0.tgz

# Fetch provenance file
helm fetch --prov bitnami/nginx
```

## Namespace Operations

```bash
# Create namespace
kubectl create namespace myns

# List releases in namespace
helm list --namespace myns

# Install in specific namespace
helm install my-release bitnami/nginx --namespace myns

# Delete namespace (and releases)
kubectl delete namespace myns
```

## Environment Variables

```bash
# Set alternative data directory
HELM_DATA_HOME=/path/to/data helm list

# Set alternative config directory  
HELM_CONFIG_HOME=/path/to/config helm list

# Disable color output
HELM_NO_COLOR=1 helm list

# Verbose output
HELM_DEBUG=1 helm install ...
```

## Kubectl Integration

```bash
# Get all Helm-managed resources
kubectl get all -l heritage=Helm

# Get all releases in cluster (Helm 3)
kubectl get helmreleases -A

# Describe Helm release (if using flux)
kubectl describe helmrelease my-release -n myns

# Watch Helm status
watch helm status my-release

# Get Helm hooks
kubectl get jobs -l app.kubernetes.io/managed-by=Helm
```

## Quick Reference

| Action | Command |
|--------|---------|
| Install | `helm install <name> <chart>` |
| Upgrade | `helm upgrade <name> <chart>` |
| Rollback | `helm rollback <name> <revision>` |
| Uninstall | `helm uninstall <name>` |
| List | `helm list` |
| Status | `helm status <name>` |
| Get values | `helm get values <name>` |
| Template | `helm template <name> <chart>` |
| Repo add | `helm repo add <name> <url>` |
| Search | `helm search repo <term>` |
| Pull | `helm pull <chart>` |
| Lint | `helm lint <chart>` |

## Tips & Tricks

```bash
# Use specific kubeconfig
KUBECONFIG=/path/to/kubeconfig helm list

# Wait for deployment ready
helm install my-release bitnami/nginx --wait --timeout 10m

# Force update (ignore old config)
helm upgrade my-release bitnami/nginx --force

# Skip hooks
helm install my-release bitnami/nginx --no-hooks

# Show all namespaces in prompts
export HELM_NAMESPACE=production
```
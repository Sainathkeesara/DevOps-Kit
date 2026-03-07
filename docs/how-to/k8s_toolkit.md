# Kubernetes Toolkit (k8s_toolkit)

## Purpose

The k8s_toolkit provides safe, opinionated helper scripts for common Kubernetes operations. These wrappers enforce best practices, add safety guards, and standardize output across teams.

## When to use

Use k8s_toolkit scripts when you need to:
- Drain nodes safely with PodDisruptionBudget respect
- Monitor deployment rollouts with timeout control
- Restart pods and verify controller recreation
- Stream pod logs with consistent options
- Debug pods interactively with integrated commands
- Generate namespace resource reports
- Manage ConfigMaps and Secrets
- Diagnose Ingress issues (backends, TLS, events)
- Monitor PVC status, usage, and bindings

Do **not** use these for production-critical automation without testing in non-production first. For CI/CD pipelines, review dry-run behavior.

## Prerequisites

- `kubectl` configured with cluster access (valid kubeconfig)
- Appropriate RBAC permissions for target operations
- For interactive scripts (`debug-pod.sh`): terminal supports colors and interactive sessions
- For metrics in `namespace-report.sh`: Metrics API must be enabled
- For TLS checks in `ingress-diagnostics.sh`: openssl for certificate parsing
- For PVC usage in `pvc-monitor.sh`: jq for JSON parsing

## Installation

No installation required. Clone the DevOps-Kit repository and use scripts directly:

```bash
git clone <repo> devops-kit
cd devops-kit
chmod +x scripts/bash/k8s_toolkit/**/*.sh
```

Ensure scripts are in your PATH or reference them with full path.

## Tools

### drain-node.sh

Safely drain a Kubernetes node, evicting pods while respecting PodDisruptionBudgets.

```bash
./scripts/bash/k8s_toolkit/node/drain-node.sh <node-name> [--dry-run] [--force] [--ignore-daemonsets]
```

**Arguments:**
- `<node-name>` - Name of the node to drain

**Options:**
- `--dry-run` - Show what would happen without making changes
- `--force` - Force eviction even if PodDisruptionBudget would block it
- `--ignore-daemonsets` - Skip DaemonSet pods (they remain running)

**What it does:**
1. Validates node exists
2. Checks if node is already marked unschedulable
3. Runs `kubectl drain` with appropriate flags
4. Cordon the node to prevent new pods

**Expected behavior:**
- Pods with PDBs are evicted gradually respecting disruption budget
- DaemonSet pods are skipped by default (use `--ignore-daemonsets` to include)
- If drain succeeds, node becomes cordoned (unschedulable)

**Rollback:**
Node remains cordoned. To make it schedulable again:
```bash
kubectl uncordon <node-name>
```

---

### rollout-status.sh

Monitor deployment/daemonset/statefulset rollout status with timeout.

```bash
./scripts/bash/k8s_toolkit/rollout-status.sh <resource-type>/<name> [--namespace=<ns>] [--timeout=<duration>]
```

**Arguments:**
- `<resource-type>/<name>` - e.g., `deployment/app-backend`

**Options:**
- `--namespace=<ns>` - Namespace (default: default)
- `--timeout=<duration>` - Timeout duration (default: 3m)

**What it does:**
- Validates resource exists and is a supported type
- Executes `kubectl rollout status` with provided timeout
- Returns exit code 0 on success, non-zero on failure/timeout

**Example:**
```bash
./scripts/bash/k8s_toolkit/rollout-status.sh deployment/my-app --timeout=5m
```

---

### restart-pod.sh

Restart a pod by deleting it (assuming controller will recreate it).

```bash
./scripts/bash/k8s_toolkit/pod/restart-pod.sh <pod-name> [--namespace=<ns>] [--grace-period=<seconds>] [--force]
```

**Arguments:**
- `<pod-name>` - Name of the pod to restart

**Options:**
- `--namespace=<ns>` - Namespace (default: default)
- `--grace-period=<seconds>` - Grace period before forced termination (default: 30)
- `--force` - Kill immediately (sets grace-period to 0)

**What it does:**
1. Validates pod exists
2. Checks if pod has a controller (deployment/statefulset/daemonset)
3. If standalone, prompts for confirmation before deletion
4. Deletes the pod
5. Waits for controller to create a replacement (if applicable)
6. Verifies new pod reaches ready state

**Expected behavior:**
- Managed pods: Controller creates replacement automatically
- Standalone pods: User warned, pod is permanently deleted

---

### pod-logs.sh

Stream or fetch logs from a pod with filtering options.

```bash
./scripts/bash/k8s_toolkit/pod/pod-logs.sh <pod-name> [--namespace=<ns>] [--since=<duration>] [--tail=<lines>] [--container=<container>] [--follow]
```

**Arguments:**
- `<pod-name>` - Name of the pod

**Options:**
- `--namespace=<ns>` - Namespace (default: default)
- `--since=<duration>` - Show logs since duration (e.g., 1h, 30m)
- `--tail=<lines>` - Number of lines to show (default: all)
- `--container=<container>` - Container name in multi-container pod
- `--follow|-f` - Follow log stream

**Examples:**
```bash
# Follow logs
./pod-logs.sh my-app --follow

# Last 100 lines from specific container
./pod-logs.sh my-app --container=sidecar --tail=100
```

---

### exec-pod.sh

Execute a command inside a pod's container.

```bash
./scripts/bash/k8s_toolkit/pod/exec-pod.sh <pod-name> <command> [args...] [--namespace=<ns>] [--container=<container>]
```

**Arguments:**
- `<pod-name>` - Target pod
- `<command>` - Command to execute (with optional args)

**Options:**
- `--namespace=<ns>` - Namespace (default: default)
- `--container=<container>` - Container name (default: first container)

**Examples:**
```bash
# Open a bash shell
./exec-pod.sh my-app /bin/bash

# Run diagnostic command
./exec-pod.sh my-app --container=app df -h

# Check process list
./exec-pod.sh my-app ps aux
```

---

### debug-pod.sh

Interactive debugging session with integrated commands.

```bash
./scripts/bash/k8s_toolkit/debug/debug-pod.sh <pod-name> [--namespace=<ns>]
```

**Arguments:**
- `<pod-name>` - Target pod

**Options:**
- `--namespace=<ns>` - Namespace (default: default)

**Interactive commands:**
- `d` - Describe pod (full kubectl describe output)
- `l` - Show last 100 log lines
- `lf` - Follow logs
- `ls` - List containers in pod
- `e` - Exec into first container (bash/sh)
- `ec <container>` - Exec into specific container
- `p` - Show pod YAML
- `eo` - Show events for this pod
- `?` or `h` - Show help
- `q` - Quit

**Example:**
```bash
./debug-pod.sh my-app --namespace=production
```

---

### namespace-report.sh

Generate a comprehensive report of resources in a namespace.

```bash
./scripts/bash/k8s_toolkit/report/namespace-report.sh [--namespace=<ns>] [--include-events] [--include-metrics]
```

**Options:**
- `--namespace=<ns>` - Namespace to report (default: default)
- `--include-events` - Include recent events (last 24h)
- `--include-metrics` - Include CPU/memory usage (requires metrics API)

**Report sections:**
- Pod count and phase breakdown
- Deployments and DaemonSets
- Services
- PersistentVolumeClaims
- Ingresses
- ConfigMaps and Secrets count
- Resource usage (CPU/memory) if available
- Recent events (optional)
- Potential issues: failed/pending pods, container restarts

**Example:**
```bash
./namespace-report.sh --namespace=monitoring --include-events --include-metrics
```

---

### configmap-manager.sh

Manage ConfigMaps and Secrets with create, update, list, and diff operations.

```bash
# List all ConfigMaps and Secrets
./scripts/bash/k8s_toolkit/configmap/configmap-manager.sh list -n <namespace>

# Get a ConfigMap
./scripts/bash/k8s_toolkit/configmap/configmap-manager.sh get <name> -n <namespace>

# Create ConfigMap from key-value pairs
./scripts/bash/k8s_toolkit/configmap/configmap-manager.sh create <name> -n <namespace> -k "key1=value1" -k "key2=value2"

# Create ConfigMap from file
./scripts/bash/k8s_toolkit/configmap/configmap-manager.sh create <name> -n <namespace> -f /path/to/config.yaml

# Update ConfigMap
./scripts/bash/k8s_toolkit/configmap/configmap-manager.sh update <name> -n <namespace> -k "newkey=newvalue"

# Delete ConfigMap or Secret
./scripts/bash/k8s_toolkit/configmap/configmap-manager.sh delete <name> -n <namespace> -t secret

# Diff local file against cluster
./scripts/bash/k8s_toolkit/configmap/configmap-manager.sh diff <name> -n <namespace> -f local-config.yaml

# Dry-run mode
DRY_RUN=true ./scripts/bash/k8s_toolkit/configmap/configmap-manager.sh create <name> -n <namespace> -k "key=value"
```

**Options:**
- `-n, --namespace` - Target namespace (default: default)
- `-t, --type` - Resource type: configmap, secret, or all (default: all)
- `-o, --output` - Output format: table, yaml, json (default: table)
- `-f, --file` - File path for create/update from file
- `-k, --key-value` - Key=value pairs (can repeat)
- `--dry-run` - Show what would happen without making changes

---

### ingress-diagnostics.sh

Diagnose Ingress issues including status, backends, TLS, and events.

```bash
# List all Ingress resources
./scripts/bash/k8s_toolkit/ingress/ingress-diagnostics.sh list -n <namespace>

# Check ingress status
./scripts/bash/k8s_toolkit/ingress/ingress-diagnostics.sh status <name> -n <namespace>

# Show backend services and endpoints
./scripts/bash/k8s_toolkit/ingress/ingress-diagnostics.sh backends <name> -n <namespace>

# Check TLS configuration
./scripts/bash/k8s_toolkit/ingress/ingress-diagnostics.sh tls <name> -n <namespace>

# Show ingress events
./scripts/bash/k8s_toolkit/ingress/ingress-diagnostics.sh events <name> -n <namespace>

# Full diagnostic report
./scripts/bash/k8s_toolkit/ingress/ingress-diagnostics.sh diagnose <name> -n <namespace>

# Test ingress from inside cluster
./scripts/bash/k8s_toolkit/ingress/ingress-diagnostics.sh curl <name> /api/health -n <namespace>
```

**Options:**
- `-n, --namespace` - Target namespace (default: default)
- `-w, --watch` - Watch mode for events
- `-v, --verbose` - Verbose output

---

### pvc-monitor.sh

Monitor PersistentVolumeClaims, usage, bindings, and unused PVCs.

```bash
# List all PVCs with status
./scripts/bash/k8s_toolkit/pvc/pvc-monitor.sh list -n <namespace>

# Show PVC details
./scripts/bash/k8s_toolkit/pvc/pvc-monitor.sh status <name> -n <namespace>

# Show storage usage
./scripts/bash/k8s_toolkit/pvc/pvc-monitor.sh usage -n <namespace>

# Find unused PVCs (no pods referencing)
./scripts/bash/k8s_toolkit/pvc/pvc-monitor.sh unused -n <namespace>

# Show pods using each PVC
./scripts/bash/k8s_toolkit/pvc/pvc-monitor.sh pods -n <namespace>

# Show PV details
./scripts/bash/k8s_toolkit/pvc/pvc-monitor.sh volume <name> -n <namespace>

# Watch PVC status
./scripts/bash/k8s_toolkit/pvc/pvc-monitor.sh watch -n <namespace>
```

**Options:**
- `-n, --namespace` - Target namespace (default: all namespaces)
- `-s, --storage-class` - Filter by storage class
- `-w, --watch` - Watch mode
- `--threshold` - Usage alert threshold percentage (default: 80)

## Common errors

### kubectl: command not found

Install kubectl: https://kubernetes.io/docs/tasks/tools/

### Unable to connect to the server

Check kubeconfig: `kubectl config current-context` and `kubectl cluster-info`.

### Error from server (Forbidden)

User lacks required RBAC permissions. Contact cluster administrator.

### Pod not found

Verify pod name and namespace: `kubectl get pods -n <namespace>`

### Node is cordoned, cannot drain

Drain requires node to be schedulable. Un-cordon first: `kubectl uncordon <node>` then retry.

### Metrics API not available

Install metrics-server: https://github.com/kubernetes-sigs/metrics-server

### Pod deletion blocked by PodDisruptionBudget

Wait for budget to allow eviction or use `--force` cautiously.

## References

- Kubernetes kubectl reference: https://kubernetes.io/docs/reference/kubectl/
- PodDisruptionBudget: https://kubernetes.io/docs/concepts/workloads/pods/disruptions/
- Drain node procedure: https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/
- Rollout status: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Kubernetes events: https://kubernetes.io/docs/concepts/cluster-administration/system-logs/
- ConfigMaps and Secrets: https://kubernetes.io/docs/concepts/configuration/configmap-secrets/
- Ingress: https://kubernetes.io/docs/concepts/services-networking/ingress/
- Persistent Volumes: https://kubernetes.io/docs/concepts/storage/persistent-volumes/

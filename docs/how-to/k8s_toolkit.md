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

Do **not** use these for production-critical automation without testing in non-production first. For CI/CD pipelines, review dry-run behavior.

## Prerequisites

- `kubectl` configured with cluster access (valid kubeconfig)
- Appropriate RBAC permissions for target operations
- For interactive scripts (`debug-pod.sh`): terminal supports colors and interactive sessions
- For metrics in `namespace-report.sh`: Metrics API must be enabled

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

### decode-secret.sh

Decode Kubernetes secrets to view their values (base64 encoded or decoded).

```bash
# List all keys in a secret
./scripts/bash/k8s_toolkit/secret/decode-secret.sh my-secret --namespace=prod

# Decode a specific key
./scripts/bash/k8s_toolkit/secret/decode-secret.sh my-secret --namespace=prod --key=password --decode

# Show all keys with decoded values
./scripts/bash/k8s_toolkit/secret/decode-secret.sh my-secret --namespace=prod --decode
```

**Arguments:**
- `<secret-name>` - Name of the secret

**Options:**
- `--namespace=<ns>` - Namespace (default: default)
- `--key=<key>` - Specific key to decode (default: all keys)
- `--decode` - Decode base64 values (default: shows encoded)

**What it does:**
- Fetches secret data from Kubernetes
- Lists all keys or a specific key
- Optionally decodes base64 values

**Security note:** Use `--decode` only in secure environments. Avoid logging decoded secrets.

---

### cleanup-jobs.sh

Clean up completed or failed Kubernetes jobs.

```bash
# Preview deletion of succeeded jobs
./scripts/bash/k8s_toolkit/job/cleanup-jobs.sh --namespace=prod

# Delete all succeeded jobs
./scripts/bash/k8s_toolkit/job/cleanup-jobs.sh --namespace=prod --status=succeeded --force

# Delete all failed jobs
./scripts/bash/k8s_toolkit/job/cleanup-jobs.sh --namespace=prod --status=failed --force

# Delete all completed jobs (succeeded + failed)
./scripts/bash/k8s_toolkit/job/cleanup-jobs.sh --namespace=prod --status=all --force
```

**Options:**
- `--namespace=<ns>` - Namespace (default: default)
- `--status=<status>` - Job status: succeeded, failed, all (default: succeeded)
- `--dry-run` - Show what would be deleted (default)
- `--force` - Actually delete jobs

**What it does:**
1. Lists jobs matching the status criteria
2. With `--dry-run`: shows jobs that would be deleted
3. With `--force`: permanently deletes matching jobs

**Caution:** Job deletion is irreversible. Always run with `--dry-run` first.

---

### context-manager.sh

Manage multiple Kubernetes contexts and namespaces.

```bash
# List all contexts with current highlighted
./scripts/bash/k8s_toolkit/context/context-manager.sh list

# Show current context and namespace
./scripts/bash/k8s_toolkit/context/context-manager.sh current

# Switch to production context
./scripts/bash/k8s_toolkit/context/context-manager.sh switch production

# Switch to production context and monitoring namespace
./scripts/bash/k8s_toolkit/context/context-manager.sh switch production monitoring

# Validate all contexts
./scripts/bash/k8s_toolkit/context/context-manager.sh validate

# Run command in specific context
./scripts/bash/k8s_toolkit/context/context-manager.sh run staging kubectl get pods
```

**Commands:**
- `list` - List all contexts (default)
- `current` - Show current context and namespace
- `switch <context> [ns]` - Switch to context, optionally set namespace
- `validate [context]` - Validate context connectivity
- `run <context> <command>` - Run command in specific context

**Examples:**
```bash
# Quick context switch with namespace
./context-manager.sh switch prod monitoring

# Validate specific context before use
./context-manager.sh validate production

# Run deployment in staging without switching context
./context-manager.sh run staging kubectl rollout status deployment/app
```

---

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

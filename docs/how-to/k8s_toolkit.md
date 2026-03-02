# Kubernetes Toolkit (k8s_toolkit)

## Purpose

The Kubernetes Toolkit provides safe, ergonomic bash wrappers around `kubectl` for common operations. Each script follows strict safety standards: dry-run support, confirmation prompts for destructive actions, and clear error messages.

## When to Use

- **Node maintenance** – Drain nodes safely with `k8s-drain-node.sh`
- **Rollout monitoring** – Track deployment updates in real-time with `k8s-rollout-status.sh`
- **Zero-downtime restarts** – Trigger a rolling restart without changing images with `k8s-restart-deployment.sh`
- **Log investigation** – Tail logs from specific pods, containers, or time ranges with `k8s-pod-logs.sh`
- **Interactive debugging** – Exec into pods and see context with `k8s-exec.sh` and `k8s-debug-pod.sh`
- **Audit reports** – Generate namespace resource summaries with `k8s-namespace-report.sh`

## Prerequisites

- `kubectl` installed and configured (test with `kubectl cluster-info`)
- Shell: Bash 4.x+ or Zsh
- Network access to your Kubernetes cluster
- RBAC:
  - Read access to pods, deployments, namespaces for info scripts
  - Edit/admin for scripts that modify state (drain, restart)
- Optional: Python 3 for namespace resource calculation (`k8s-namespace-report.sh --resource-limit`)

## Installation

No installation needed – scripts are portable. Clone or copy the `scripts/bash/k8s_toolkit/` directory to your workstation and make scripts executable:

```bash
chmod +x scripts/bash/k8s_toolkit/*.sh
```

Optional: Add to your `PATH`:

```bash
export PATH="$PATH:/path/to/devops-kit/scripts/bash/k8s_toolkit"
```

## Step-by-Step Usage

### Draining a Node

1. Identify the node: `kubectl get nodes`
2. Cordon the node (optional but recommended): `kubectl cordon <node>`
3. Run drain with appropriate flags:

```bash
./k8s-drain-node.sh <node-name> --timeout=300 --ignore-daemonsets --delete-emptydir-data
```

4. The script will:
   - Show all pods currently on the node
   - Prompt for confirmation
   - Execute `kubectl drain` with your options
   - Report success or failure

5. After maintenance, uncordon: `kubectl uncordon <node>`

### Monitoring a Rollout

```bash
# Check status once with timeout
./k8s-rollout-status.sh my-deployment -n prod --timeout=600

# Watch continuously until complete
./k8s-rollout-status.sh my-deployment -n prod --watch
```

The script auto-detects if the resource is a Deployment, DaemonSet, or StatefulSet.

### Restarting a Deployment

```bash
# Dry-run first to see the exact patch
./k8s-restart-deployment.sh my-app -n staging --dry-run

# Confirm and restart, waiting up to 10 minutes
./k8s-restart-deployment.sh my-app -n prod --timeout=600
```

This updates the pod template's `restartedAt` annotation, forcing pods to restart with the same image.

### Fetching Pod Logs

```bash
# Tail last 500 lines
./k8s-pod-logs.sh mypod -n default --tail=500

# Logs from a specific container in the last hour
./k8s-pod-logs.sh mypod -n prod --container sidecar --since=1h

# Follow live logs (like kubectl logs -f)
./k8s-pod-logs.sh mypod -it -f
```

### Executing Commands Inside Pods

```bash
# Run a one-off command
./k8s-exec.sh mypod -n default "df -h"

# Interactive shell (TTY allocation)
./k8s-exec.sh mypod -n default -it --container app /bin/bash

# If the container lacks bash, use default shell fallback
./k8s-exec.sh mypod -it --shell /bin/sh
```

### Debugging a Problematic Pod

```bash
# Full debug session (logs, events, YAML, then exec)
./k8s-debug-pod.sh failing-pod -n prod

# Only view information, no exec
./k8s-debug-pod.sh failing-pod -n prod --no-exec

# Include previous container logs (crashed containers)
./k8s-debug-pod.sh failing-pod -n prod --previous --logs-tail=300
```

The script outputs:
- Pod details (status, node, IP)
- Full pod spec in YAML
- Recent events sorted by timestamp
- Logs from all containers
- Interactive exec into the first container

### Generating a Namespace Report

```bash
# Summary of all namespaces
./k8s-namespace-report.sh

# Specific namespace
./k8s-namespace-report.sh -n kube-system

# Include resource requests/limits (requires Python3)
./k8s-namespace-report.sh -n prod --resource-limit

# JSON output for automation
./k8s-namespace-report.sh --output json > ns-report.json
```

## Verify

Test that scripts are executable and work in your environment:

```bash
# Check kubectl connectivity
kubectl get nodes

# Run a read-only script with dry-run if available
./k8s-namespace-report.sh -n default

# Check syntax (no execution)
bash -n scripts/bash/k8s_toolkit/*.sh
```

On a non-production cluster, try:
```bash
./k8s-drain-node.sh <test-node> --dry-run
```

## Rollback

None of these scripts perform irreversible actions **except**:
- `k8s-drain-node.sh` – evicts pods. Rollback: `kubectl uncordon <node>` and manually scale up deployments if needed.
- `k8s-restart-deployment.sh` – performs a rolling restart. If pods fail: `kubectl rollout undo deployment/<name>`

All other scripts are read-only.

## Common Errors

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| `kubectl: command not found` | kubectl not installed or not in PATH | Install kubectl and configure kubectl config |
| `error: You must be logged in to the server` | No current context or expired credentials | Run `kubectl config use-context <valid-context>` and re-authenticate if needed |
| `pdb .... prevented eviction` | PodDisruptionBudget blocks eviction on drain | Update PDB or use `--force` (risky) |
| `deployment not found` | Wrong namespace or name | Add `-n <namespace>` or check spelling |
| `permission denied` on scripts | Script not executable | `chmod +x scripts/bash/k8s_toolkit/*.sh` |
| `exec: “/bin/bash”: stat /bin/bash: no such file or directory` | Container image lacks bash | Use `--shell /bin/sh` or specify a shell that exists |
| `timed out waiting for the condition` on rollout | New pods failing to become ready | Check pod events/logs with `k8s-debug-pod.sh` |

## References

- Official kubectl docs: https://kubernetes.io/docs/reference/kubectl/
- Kubernetes drain considerations: https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/
- Rollout strategies: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl exec: https://kubernetes.io/docs/reference/kubectl/cheatsheet/#interacting-with-running-pods

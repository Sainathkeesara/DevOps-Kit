# Kubernetes Toolkit (k8s_toolkit)

A collection of safe, production-ready Bash helpers for common Kubernetes operations.

## Scripts

| Script | Purpose |
|--------|---------|
| `k8s-drain-node.sh` | Safely drain a node (evict pods gracefully) |
| `k8s-rollout-status.sh` | Monitor deployment/rollout status with watch option |
| `k8s-restart-deployment.sh` | Restart a deployment by patching pod template |
| `k8s-pod-logs.sh` | Fetch pod logs with tail/since/container options |
| `k8s-exec.sh` | Execute commands inside pods with interactive mode |
| `k8s-debug-pod.sh` | Comprehensive pod debugging (info, events, logs, exec) |
| `k8s-namespace-report.sh` | Generate resource usage report for namespaces |

## Usage

All scripts support `-h` or `--help` to show usage. Most scripts also support:

- `--dry-run` – Show what would be done without executing
- `-n <namespace>` or positional namespace argument
- Verbose logging to stderr

### Examples

```bash
# Drain a node safely
./k8s-drain-node.sh node-1 --timeout=300 --ignore-daemonsets

# Watch a rollout
./k8s-rollout-status.sh my-deployment -n prod --watch

# Restart a deployment
./k8s-restart-deployment.sh my-app --namespace staging

# View pod logs
./k8s-pod-logs.sh mypod -n default --tail=500 --since=1h

# Exec into a pod
./k8s-exec.sh mypod -it --container app sh

# Debug a problematic pod
./k8s-debug-pod.sh failing-pod -n monitoring --logs-tail=100 --previous

# Get namespace report
./k8s-namespace-report.sh -n kube-system --resource-limit
```

## Safety Features

- All deletion/changing operations require confirmation (unless `--dry-run`)
- Non-destructive by default; read-only operations are safe to run anytime
- Proper error handling and logging via `set -euo pipefail`
- Input validation and clear error messages
- Timeouts for long-running operations

## Prerequisites

- `kubectl` configured and connected to your cluster
- Appropriate RBAC permissions (view, edit, or admin depending on script)
- Bash 4.x+ (for associative arrays and extended features)

## Integration with devops-kit

This toolkit follows the [Script Standard](../00_index/glossary.md#script-standard). See the [how-to guide](../docs/how-to/k8s_toolkit.md) for detailed usage patterns and best practices.

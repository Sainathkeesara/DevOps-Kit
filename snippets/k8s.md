# Kubernetes Snippets

Copy-and-paste commands for Kubernetes. See also the [k8s_toolkit](../docs/how-to/k8s_toolkit.md) for wrappers around these.

## Quick Config

```bash
# Show current context
kubectl config current-context

# List all contexts
kubectl config get-contexts

# Use a context
kubectl config use-context my-cluster

# Show cluster info
kubectl cluster-info
```

## Pods

```bash
# Get all pods in all namespaces
kubectl get pods --all-namespaces

# Pods with more info
kubectl get pods -o wide

# Delete a pod (use with caution)
kubectl delete pod mypod -n mynamespace

# Port forward
kubectl port-forward pod/mypod 8080:80

# Quick one-liner: pod description and last logs
kubectl describe pod mypod -n mynamespace && \
kubectl logs mypod -n mynamespace --tail=50
```

## Deployments

```bash
# Check rollout status
kubectl rollout status deployment/my-deployment -n mynamespace

# Pause rollout
kubectl rollout pause deployment/my-deployment -n mynamespace

# Resume rollout
kubectl rollout resume deployment/my-deployment -n mynamespace

# Undo rollout
kubectl rollout undo deployment/my-deployment -n mynamespace

# Scale
kubectl scale deployment my-deployment --replicas=5 -n mynamespace
```

## Namespaces

```bash
# List all namespaces
kubectl get ns

# Create namespace
kubectl create namespace my-namespace

# Delete namespace (slow)
kubectl delete namespace my-namespace

# Resource usage by namespace (requires metrics-server)
kubectl top pods --all-namespaces
```

## Debug

```bash
# Get pod logs (all containers)
kubectl logs mypod -n mynamespace --all-containers=true

# Previous container logs (crashed)
kubectl logs mypod -n mynamespace --previous

# Exec into pod
kubectl exec -it mypod -n mynamespace -- /bin/bash

# Describe events (sorted)
kubectl get events -n mynamespace --sort-by='.lastTimestamp'

# Show only pending pods
kubectl get pods --field-selector=status.phase=Pending -n mynamespace
```

## k8s_toolkit Scripts

```bash
# Draining a node (safe)
./scripts/bash/k8s_toolkit/k8s-drain-node.sh node-1 --ignore-daemonsets --timeout=300

# Monitoring rollout
./scripts/bash/k8s_toolkit/k8s-rollout-status.sh my-deployment --watch

# Restart deployment without image change
./scripts/bash/k8s_toolkit/k8s-restart-deployment.sh my-app

# Pod logs with filters
./scripts/bash/k8s_toolkit/k8s-pod-logs.sh mypod --tail=200 --since=1h

# Exec with container selection
./scripts/bash/k8s_toolkit/k8s-exec.sh mypod -it --container app sh

# Full debug session
./scripts/bash/k8s_toolkit/k8s-debug-pod.sh failing-pod

# Namespace report
./scripts/bash/k8s_toolkit/k8s-namespace-report.sh --resource-limit
```

# Kubectl Cheatsheet

## Quick Reference

### Get resources
```bash
kubectl get pods
kubectl get pods -n <namespace>
kubectl get all
kubectl get pods -o wide
kubectl get pods --show-labels
```

### Describe
```bash
kubectl describe pod <pod-name>
kubectl describe deployment <name>
kubectl describe node <node-name>
```

### Logs
```bash
kubectl logs <pod-name>
kubectl logs -f <pod-name>              # follow
kubectl logs --since=1h <pod-name>
kubectl logs --tail=100 <pod-name>
kubectl logs -c <container> <pod-name>  # multi-container pod
```

### Exec into pod
```bash
kubectl exec <pod-name> -- /bin/bash
kubectl exec -it <pod-name> -- /bin/sh
kubectl exec -c <container> <pod-name> -- <command>
```

### Port forward
```bash
kubectl port-forward pod/<pod-name> 8080:80
kubectl port-forward svc/<service-name> 8080:80
```

### Apply/Delete
```bash
kubectl apply -f <manifest.yaml>
kubectl delete -f <manifest.yaml>
kubectl delete pod <pod-name>
kubectl delete pod <pod-name> --grace-period=0 --force
```

### Drain/Cordon/Uncordon
```bash
kubectl cordon <node-name>
kubectl uncordon <node-name>
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

### Rollout
```bash
kubectl rollout status deployment/<name>
kubectl rollout restart deployment/<name>
kubectl rollout undo deployment/<name>
```

### Config/Context
```bash
kubectl config get-contexts
kubectl config use-context <context-name>
kubectl config current-context
kubectl config view
```

### Namespace
```bash
kubectl get namespaces
kubectl create namespace <name>
kubectl config set-context --current --namespace=<name>
```

### Labels/Annotations
```bash
kubectl label pods <pod-name> env=prod
kubectl label pods <pod-name> env-  # remove label
kubectl get pods -l env=prod
kubectl get pods --all-labels
```

### Events
```bash
kubectl get events
kubectl get events --sort-by='.lastTimestamp'
kubectl get events -n <namespace>
kubectl describe pod <pod-name> | grep -A 10 Events
```

### Debugging
```bash
kubectl get pods -o wide               # see node assignment
kubectl top pods                       # resource usage (metrics-server required)
kubectl top nodes
kubectl get pod <pod-name> -o yaml     # full manifest
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].name}'  # list containers
```

### Common flags
- `-n <namespace>` or `--namespace=<namespace>` - specify namespace
- `-o <format>` or `--output=<format>` - output format (json, yaml, wide, name)
- `-f <file>` or `--filename=<file>` - file/URL to read
- `--dry-run=client` - validate without applying
- `--all` - select all resources in namespace
- `--all-namespaces` - across all namespaces
- `-l <key=value>` - label selector

## One-liners

```bash
# Restart all deployments in namespace
kubectl rollout restart deployment -n <namespace>

# Delete all pods with label app=old
kubectl delete pods -l app=old

# List pods sorted by restart count
kubectl get pods -o custom-columns=NAME:.metadata.name,RESTARTS:.status.containerStatuses[0].restartCount --sort-by='.status.containerStatuses[0].restartCount'

# Show pods with their IPs
kubectl get pods -o custom-columns=NAME:.metadata.name,IP:.status.podIP

# Watch pods continuously
kubectl get pods -w

# Copy file from pod to local
kubectl cp <pod-name>:/path/to/remote/file ./local/file

# Copy local file to pod
kubectl cp ./local/file <pod-name>:/remote/path
```

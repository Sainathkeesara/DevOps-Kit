# Troubleshooting CrashLoopBackOff

## Purpose

Diagnose and resolve CrashLoopBackOff status in Kubernetes pods. This error indicates a container is repeatedly crashing after startup.

## When to use

- Pod status shows `CrashLoopBackOff` in `kubectl get pods`
- Container restarts count is increasing rapidly
- Application fails to stay running after deployment

## Prerequisites

- `kubectl` configured with cluster access
- Access to container logs (`kubectl logs`)
- Permission to describe resources (`kubectl describe`)
- For deeper debugging: exec access (`kubectl exec`)

## Steps

### 1. Identify the failing pod

```bash
kubectl get pods -n <namespace>
```

Note the pod name and observe the `RESTARTS` and `STATUS` columns.

### 2. Check container logs

```bash
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous
```

The `--previous` flag shows logs from the container's previous run, which often contains the actual crash trace.

### 3. Describe the pod for events

```bash
kubectl describe pod <pod-name> -n <namespace>
```

Look at the `Events` section at the bottom. Common events include:
- `BackOff` — container is being restarted due to failure
- `Killing` — container was terminated
- `Started` — container started (but then crashed)

### 4. Identify root cause from exit code

```bash
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.status.containerStatuses[*]}'
```

Check the `lastTerminationState.exitCode`:
- `1` or `127` — application error (check logs)
- `137` (128+9) — SIGKILL, likely OOMKilled
- `143` (128+15) — SIGTERM, graceful termination timeout
- `0` — may indicate successful exit then restart (application exits itself)

### 5. Common causes and fixes

#### a. Application error (exit code non-zero)

Check logs for stack traces or error messages. Common fixes:
- Fix application code or configuration
- Verify environment variables are set correctly
- Check configmaps and secrets are mounted properly

#### b. Out of memory (OOMKilled)

```bash
kubectl describe pod <pod-name> -n <namespace> | grep -i "last terminated"
```

If OOMKilled:
- Increase memory request/limit in the pod spec:
  ```yaml
  resources:
    requests:
      memory: "256Mi"
    limits:
      memory: "512Mi"
  ```
- Profile application memory usage
- Check for memory leaks in application

#### c. Liveness probe failure

```bash
kubectl get pod <pod-name> -n <namespace> -o yaml | grep -A 10 livenessProbe
```

If liveness probe is failing:
- Adjust probe parameters (initialDelaySeconds, periodSeconds, failureThreshold)
- Ensure application has enough startup time
- Check if probe endpoint is correct and accessible

#### d. Missing dependencies

- ConfigMaps or Secrets not mounted
- External service unavailable (database, API)
- Volume mount paths incorrect

#### e. Image issues

- Wrong image name or tag
- Image pull policy (`Always` vs `IfNotPresent`)
- Private registry authentication missing

### 6. Interactive debugging

For persistent issues, spawn a debug container:

```bash
kubectl debug <pod-name> -n <namespace> --image=busybox --restart=Never -- sh
```

Or copy files from crashing container:

```bash
kubectl debug <pod-name> -n <namespace> --image=busybox --copy-to=<pod-name>-debug
```

## Verify

After applying fixes:

```bash
# Watch pod status
kubectl get pod <pod-name> -n <namespace> -w

# Verify no restarts for extended period
kubectl get pods -n <namespace> | grep <pod-name>
# Confirm RESTARTS count is stable
```

## Rollback

If the issue started after a deployment:

```bash
# Rollback to previous revision
kubectl rollout undo deployment/<deployment-name> -n <namespace>

# Or specify revision
kubectl rollout undo deployment/<deployment-name> -n <namespace> --to-revision=<n>
```

## Common errors

| Error | Cause | Fix |
|-------|-------|-----|
| Exit code 1 | Application error | Check logs for stack trace |
| Exit code 137 | OOMKilled | Increase memory limits |
| Exit code 143 | SIGTERM timeout | Increase terminationGracePeriodSeconds |
| ImagePullBackOff | Image not found or auth failed | Check image name and registry secrets |
| ErrImagePull | Tag does not exist | Verify image tag |
| Liveness probe failed | Probe endpoint not responding | Adjust probe config or fix app |

## References

- Kubernetes Pod Lifecycle — https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/ (verified: 2026-03-07)
- Debug Running Pods — https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/ (verified: 2026-03-07)
- Pod OOMKilled Troubleshooting — https://kubernetes.io/docs/tasks/debug/debug-application/oomkill/ (verified: 2026-03-07)

# Kubernetes RBAC

## Purpose

Kubernetes Role-Based Access Control (RBAC) restricts cluster resource access to authorized users and workloads. This document covers the core RBAC API objects and provides practical examples for implementing fine-grained access control.

## When to use

- Granting namespace-level permissions to users, groups, or service accounts
- Granting cluster-wide permissions across all namespaces
- Implementing least-privilege access for applications running in the cluster
- Auditing and managing permissions in production clusters

## Prerequisites

- Kubernetes cluster v1.8+ with RBAC enabled (default since v1.8)
- `kubectl` configured with cluster access
- Permissions to create RBAC resources (admin or RBAC admin role)

## Steps

### 1. Understanding RBAC API Objects

Kubernetes RBAC uses four API objects:

| Object | Scope | Use Case |
|--------|-------|----------|
| Role | Namespace | Grant permissions within a specific namespace |
| ClusterRole | Cluster | Grant permissions cluster-wide or to cluster-scoped resources |
| RoleBinding | Namespace | Bind a Role or ClusterRole to users within a namespace |
| ClusterRoleBinding | Cluster | Bind a ClusterRole to users cluster-wide |

### 2. Creating a Role

A Role grants permissions to resources within a single namespace.

```yaml
# role-read-pods.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
```

Apply the Role:

```bash
kubectl apply -f role-read-pods.yaml
```

### 3. Creating a RoleBinding

RoleBinding grants the Role permissions to users, groups, or service accounts.

```yaml
# rolebinding-read-pods.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods-binding
  namespace: default
subjects:
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
- kind: Group
  name: dev-team
  apiGroup: rbac.authorization.k8s.io
- kind: ServiceAccount
  name: my-app
  namespace: production
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Apply the RoleBinding:

```bash
kubectl apply -f rolebinding-read-pods.yaml
```

### 4. Creating a ClusterRole

ClusterRole grants permissions cluster-wide or to cluster-scoped resources (nodes, persistentvolumes, namespaces).

```yaml
# clusterrole-node-reader.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "watch"]
```

Apply the ClusterRole:

```bash
kubectl apply -f clusterrole-node-reader.yaml
```

### 5. Creating a ClusterRoleBinding

ClusterRoleBinding grants ClusterRole permissions cluster-wide.

```yaml
# clusterbindingapiVersion: r-node-reader.yaml
bac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node-reader-binding
subjects:
- kind: User
  name: admin-user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: node-reader
  apiGroup: rbac.authorization.k8s.io
```

Apply the ClusterRoleBinding:

```bash
kubectl apply -f clusterbinding-node-reader.yaml
```

### 6. Using ClusterRole for Namespace-Specific Permissions

ClusterRole can be referenced by RoleBinding to grant namespace-scoped permissions without creating separate Role objects.

```yaml
# rolebinding-cluster-admin.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: admin-binding
  namespace: production
subjects:
- kind: User
  name: prod-admin
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: admin
  apiGroup: rbac.authorization.k8s.io
```

### 7. Aggregating ClusterRoles

Use labels to combine multiple rules into a single ClusterRole using `aggregationRule`.

```yaml
# clusterrole-aggregate.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: custom-reader
  labels:
    rbac.authorization.k8s.io/aggregate-to-view: "true"
aggregationRule:
  clusterRoleSelectors:
  - matchLabels:
      rbac.authorization.k8s.io/aggregate-to-view: "true"
rules: [] # Rules are automatically filled by the controller
```

### 8. Granting API Group Permissions

Different API groups require explicit specification.

```yaml
# role-full-deployment.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: apps
  name: deployment-manager
rules:
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
```

### 9. Granting Resource-Specific Permissions

Use `resourceNames` to restrict access to specific named resources.

```yaml
# role-specific-configmap.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: configmap-updater
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["app-config", "feature-flags"]
  verbs: ["get", "update", "patch"]
```

## Verify

### Check Role permissions:

```bash
kubectl get role -n <namespace>
kubectl describe role <role-name> -n <namespace>
```

### Check RoleBinding:

```bash
kubectl get rolebinding -n <namespace>
kubectl describe rolebinding <binding-name> -n <namespace>
```

### Check ClusterRole:

```bash
kubectl get clusterrole
kubectl describe clusterrole <clusterrole-name>
```

### Check ClusterRoleBinding:

```bash
kubectl get clusterrolebinding
kubectl describe clusterrolebinding <binding-name>
```

### Check user permissions:

```bash
# Using kubectl auth can-i
kubectl auth can-i get pods --as=jane -n default
kubectl auth can-i delete pods --as=jane -n default
kubectl auth can-i get nodes --as=admin-user

# Using kubectl auth reconcile (check for missing permissions)
kubectl auth reconcile -f role.yaml
```

### View effective permissions for a user:

```bash
# Requires RBAC permissions to query
kubectl auth can-i --list --as=<user>
```

## Rollback

To remove permissions:

```bash
# Remove RoleBinding
kubectl delete rolebinding <binding-name> -n <namespace>

# Remove ClusterRoleBinding
kubectl delete clusterrolebinding <binding-name>

# Remove Role
kubectl delete role <role-name> -n <namespace>

# Remove ClusterRole
kubectl delete clusterrole <clusterrole-name>
```

To audit changes:

```bash
# View RBAC audit logs in kube-apiserver
kubectl logs -n kube-system kube-apiserver-<pod-name> | grep -i rbac
```

## Common errors

### "User cannot list pods in namespace"

Cause: Missing or incorrect RoleBinding. Verify the subject is correctly defined.

```bash
# Check what permissions the user actually has
kubectl auth can-i list pods --as=<user> -n <namespace> -v 7
```

### "Role references cannot be changed"

Cause: RoleRef is immutable after creation. Delete and recreate the RoleBinding.

```bash
kubectl delete rolebinding <name> -n <namespace>
kubectl apply -f new-rolebinding.yaml
```

### "User not found" or "Group not found"

Cause: External authentication provider (OIDC, LDAP) not properly configured. Users must exist in the authentication system before authorization can grant access.

### "ClusterRole used in RoleBinding cannot grant permissions outside namespace"

Cause: ClusterRole with cluster-scoped resources cannot be used in RoleBinding. Use cluster-scoped resources only in ClusterRoleBinding.

### "Cannot modify ClusterRole with aggregationRule"

Cause: Aggregated ClusterRoles are read-only. Modify the source ClusterRoles with the aggregation labels instead.

## References

- Kubernetes RBAC Documentation — https://kubernetes.io/docs/reference/access-authn-authz/rbac/ (verified: 2026-03-11)
- Using RBAC Authorization — https://kubernetes.io/docs/reference/access-authn-authz/rbac/ (verified: 2026-03-11)
- API Groups — https://kubernetes.io/docs/concepts/overview/kubernetes-api/#api-groups (verified: 2026-03-11)

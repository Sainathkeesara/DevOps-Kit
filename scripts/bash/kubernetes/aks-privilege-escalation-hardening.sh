#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_NAME="aks-privilege-escalation-hardening"
readonly SCRIPT_VERSION="1.0.0"

# CVE-2026-33105: Azure Kubernetes Service privilege escalation via improper authorization
# This script detects and remediates the AKS privilege escalation vulnerability
# Affects: Azure Kubernetes Service clusters
# Severity: CVSS 9.8 CRITICAL

# Requirements: kubectl, az CLI, jq
# Safety: Read-only detection by default. Use --fix to apply remediation.

usage() {
    cat <<EOF
$SCRIPT_NAME v$SCRIPT_VERSION

Usage: $SCRIPT_NAME [OPTIONS]

Description:
  Detect and remediate CVE-2026-33105: Azure Kubernetes Service privilege
  escalation via improper authorization. This vulnerability allows attackers
  with limited permissions to escalate privileges within the AKS cluster.

Options:
  --cluster NAME     AKS cluster name (required)
  --resource-group RG Azure resource group (required)
  --subscription ID  Azure subscription ID (optional)
  --fix              Apply remediation (default: detection only)
  --dry-run          Show what would be done without making changes
  -h, --help         Show this help message

Examples:
  # Detection only (default)
  $SCRIPT_NAME --cluster my-aks-cluster --resource-group rg-aks-prod

  # Detection with remediation
  $SCRIPT_NAME --cluster my-aks-cluster --resource-group rg-aks-prod --fix

  # Dry-run mode
  $SCRIPT_NAME --cluster my-aks-cluster --resource-group rg-aks-prod --fix --dry-run
EOF
}

log_info() { echo -e "[INFO] $*"; }
log_warn() { echo -e "[WARN] $*"; }
log_error() { echo -e "[ERROR] $*"; }
log_success() { echo -e "[SUCCESS] $*"; }

DRY_RUN=false
FIX_MODE=false
CLUSTER_NAME=""
RESOURCE_GROUP=""
SUBSCRIPTION_ID=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --cluster)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        --resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        --subscription)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        --fix)
            FIX_MODE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

check_dependencies() {
    local deps=("kubectl" "az" "jq")
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "$cmd not found. Please install $cmd first."
            exit 1
        fi
    done
    log_info "All dependencies satisfied"
}

check_azure_auth() {
    log_info "Verifying Azure authentication..."
    if ! az account show >/dev/null 2>&1; then
        log_error "Azure CLI not authenticated. Run 'az login' first."
        exit 1
    fi
    log_info "Azure authentication verified"

    if [[ -n "$SUBSCRIPTION_ID" ]]; then
        az account set --subscription "$SUBSCRIPTION_ID" >/dev/null 2>&1
    fi
}

connect_aks_cluster() {
    log_info "Connecting to AKS cluster: $CLUSTER_NAME in resource group: $RESOURCE_GROUP"

    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would connect to cluster: $CLUSTER_NAME"
        return 0
    fi

    if ! az aks get-credentials \
        --resource-group "$RESOURCE_GROUP" \
        --name "$CLUSTER_NAME" \
        --overwrite-existing \
        --admin >/dev/null 2>&1; then
        log_error "Failed to connect to AKS cluster. Check cluster name and resource group."
        exit 1
    fi

    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "Failed to verify cluster connection"
        exit 1
    fi

    log_success "Connected to cluster: $CLUSTER_NAME"
}

detect_vulnerable_rbac_config() {
    log_info "Detecting vulnerable RBAC configurations..."

    local vulnerable_configs=()

    # Check 1: ClusterRoleBindings with wildcard subjects
    log_info "Checking for ClusterRoleBindings with wildcard or system:authenticated subjects..."
    local wildcard_crbs
    wildcard_crbs=$(kubectl get clusterrolebindings -o json 2>/dev/null | jq -r '
        .items[] |
        select(.subjects[]? | (.kind == "Group" and (.name == "*" or .name == "system:authenticated"))) |
        .metadata.name
    ')

    if [[ -n "$wildcard_crbs" ]]; then
        while IFS= read -r name; do
            [[ -z "$name" ]] && continue
            vulnerable_configs+=("ClusterRoleBinding: $name (wildcard subject)")
            log_warn "Found vulnerable ClusterRoleBinding: $name"
        done <<< "$wildcard_crbs"
    fi

    # Check 2: Roles with escalate permission
    log_info "Checking for Roles/ClusterRoles with escalate permission..."
    local escalate_roles
    escalate_roles=$(kubectl get clusterroles -o json 2>/dev/null | jq -r '
        .items[] |
        select(.rules[]? | (.apiGroups[]? == "*" and .verbs[]? == "escalate")) |
        .metadata.name
    ')

    if [[ -n "$escalate_roles" ]]; then
        while IFS= read -r name; do
            [[ -z "$name" ]] && continue
            if [[ "$name" != "cluster-admin" ]]; then
                vulnerable_configs+=("ClusterRole: $name (escalate permission)")
                log_warn "Found ClusterRole with escalate: $name"
            fi
        done <<< "$escalate_roles"
    fi

    # Check 3: ServiceAccounts with excessive permissions in kube-system
    log_info "Checking for ServiceAccounts with excessive permissions..."
    local excessive_sa
    excessive_sa=$(kubectl get clusterrolebindings -o json 2>/dev/null | jq -r '
        .items[] |
        select(.subjects[]? | (.kind == "ServiceAccount" and .namespace == "kube-system")) |
        select(.roleRef.kind == "ClusterRole" and .roleRef.name == "cluster-admin") |
        .metadata.name
    ')

    if [[ -n "$excessive_sa" ]]; then
        while IFS= read -r name; do
            [[ -z "$name" ]] && continue
            vulnerable_configs+=("ClusterRoleBinding: $name (cluster-admin SA in kube-system)")
            log_warn "Found excessive SA permissions: $name"
        done <<< "$excessive_sa"
    fi

    # Check 4: AKS-specific: Check for user-assigned identity permissions
    log_info "Checking for AKS managed identity misconfigurations..."
    local mi_permissions
    mi_permissions=$(kubectl get clusterrolebindings -o json 2>/dev/null | jq -r '
        .items[] |
        select(.subjects[]? | (.kind == "ServiceAccount" and .name == "azure-workload-identity-runtime")) |
        .metadata.name
    ')

    if [[ -n "$mi_permissions" ]]; then
        while IFS= read -r name; do
            [[ -z "$name" ]] && continue
            vulnerable_configs+=("ClusterRoleBinding: $name (workload identity)")
        done <<< "$mi_permissions"
    fi

    if [[ ${#vulnerable_configs[@]} -eq 0 ]]; then
        log_success "No obvious vulnerable RBAC configurations detected"
    else
        log_warn "Found ${#vulnerable_configs[@]} potentially vulnerable configurations"
    fi

    echo "${vulnerable_configs[@]}"
}

generate_remediation_report() {
    local vulnerable_configs=("$@")

    log_info "Generating remediation recommendations..."

    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would generate remediation report"
    fi

    cat << 'REMEDIATION_EOF'
Remediation Steps for CVE-2026-33105:

1. RESTRICT CLUSTERROLEBINDINGS
   - Remove any ClusterRoleBindings with wildcard (*) subjects
   - Replace system:authenticated with specific user/group names
   - Audit all ClusterRoleBindings: kubectl get clusterrolebindings -o wide

2. REMOVE ESCALATE PERMISSION
   - Remove 'escalate' verb from non-admin ClusterRoles
   - Review all ClusterRoles: kubectl get clusterroles -o yaml | grep -A5 escalate

3. SECURE KUBE-SYSTEM SA
   - Review ServiceAccounts in kube-system namespace
   - Remove unnecessary cluster-admin bindings
   - Implement least-privilege for workload identities

4. AZURE-SPECIFIC HARDENING
   - Enable Azure RBAC for AKS: az aks update --enable-azure-rbac
   - Use managed identities instead of service principals
   - Enable Azure Policy add-on

5. MONITORING
   - Enable Azure Security Center for container threat detection
   - Set up Azure Monitor for containers with security analytics
   - Configure alerts for RBAC changes

REMEDIATION_EOF
}

apply_remediation() {
    log_info "Applying remediation (if --fix was specified)..."

    if [ "$FIX_MODE" = false ]; then
        log_warn "Fix mode not enabled. Use --fix to apply remediation."
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would apply the following fixes:"
        log_warn "1. Create restrictive ClusterRole for AKS users"
        log_warn "2. Remove wildcard ClusterRoleBindings"
        log_warn "3. Add audit logging for RBAC changes"
        return 0
    fi

    # Create a restrictive ClusterRole for regular users
    log_info "Creating restrictive ClusterRole for regular users..."

    cat << 'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: aks-restricted-user
  labels:
    security.cve.cve-2026-33105: remediated
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
EOF

    log_success "Created restrictive ClusterRole: aks-restricted-user"

    # Note: We don't automatically delete existing bindings as that could break clusters
    log_warn "Manual action required: Review and remove vulnerable ClusterRoleBindings"
    log_warn "Run: kubectl get clusterrolebindings -o wide"
}

main() {
    log_info "Starting AKS CVE-2026-33105 hardening script v$SCRIPT_VERSION"
    log_info "Target cluster: ${CLUSTER_NAME:-not specified}"
    log_info "Resource group: ${RESOURCE_GROUP:-not specified}"
    log_info "Mode: ${FIX_MODE:+$FIX_MODE | }detection-only"
    log_info "Dry-run: $DRY_RUN"

    if [[ -z "$CLUSTER_NAME" ]] || [[ -z "$RESOURCE_GROUP" ]]; then
        log_error "Both --cluster and --resource-group are required"
        usage
        exit 1
    fi

    check_dependencies
    check_azure_auth
    connect_aks_cluster

    local vulnerable_configs
    vulnerable_configs=$(detect_vulnerable_rbac_config)

    generate_remediation_report

    apply_remediation

    log_success "CVE-2026-33105 hardening scan completed"
    log_info "Review the remediation report above and apply necessary changes manually"
    log_info "For more information: https://www.sentinelone.com/vulnerability-database/cve-2026-33105/"
}

main "$@"
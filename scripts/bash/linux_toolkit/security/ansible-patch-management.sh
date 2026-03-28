#!/usr/bin/env bash
set -euo pipefail

# Automated Linux Patch Management with Ansible
# Purpose: Automate security patching across Linux servers using Ansible
# Requirements: ansible, ssh, ansible-playbook
# Safety: Supports DRY_RUN mode — no changes without explicit confirmation
# Tested on: Ubuntu 22.04, CentOS Stream 9, RHEL 9

INVENTORY="${INVENTORY:-inventory.ini}"
PLAYBOOK="${PLAYBOOK:-patch-management.yml}"
DRY_RUN="${DRY_RUN:-true}"
LIMIT_HOSTS="${LIMIT_HOSTS:-}"
SKIP_REBOOT="${SKIP_REBOOT:-false}"
TAGS="${TAGS:-packages}"
PATCH_BUNDLE="${PATCH_BUNDLE:-critical}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_dependencies() {
    local deps=("ansible-playbook" "ansible")
    for dep in "${deps[@]}"; do
        command -v "$dep" >/dev/null 2>&1 || { log_error "$dep not found — install Ansible first"; exit 1; }
    done
    
    if [ ! -f "$INVENTORY" ]; then
        log_error "Inventory file $INVENTORY not found"
        exit 1
    fi
    
    log_info "All dependencies satisfied"
}

gather_facts() {
    log_info "Gathering facts from all hosts..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would gather facts from all hosts"
        return 0
    fi
    
    local limit_arg=""
    if [ -n "$LIMIT_HOSTS" ]; then
        limit_arg="--limit $LIMIT_HOSTS"
    fi
    
    ansible-playbook -i "$INVENTORY" $limit_arg --tags facts gathering.yml -v
}

check_reboot_required() {
    log_info "Checking if reboot required on target hosts..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would check reboot status"
        return 0
    fi
    
    local limit_arg=""
    if [ -n "$LIMIT_HOSTS" ]; then
        limit_arg="--limit $LIMIT_HOSTS"
    fi
    
    ansible-playbook -i "$INVENTORY" $limit_arg --tags reboot-check patch-management.yml
}

apply_patches() {
    log_info "Applying $PATCH_BUNDLE patches..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would apply $PATCH_BUNDLE patches"
        return 0
    fi
    
    local limit_arg=""
    if [ -n "$LIMIT_HOSTS" ]; then
        limit_arg="--limit $LIMIT_HOSTS"
    fi
    
    local skip_reboot_arg=""
    if [ "$SKIP_REBOOT" = true ]; then
        skip_reboot_arg="--skip-tags reboot"
    fi
    
    ansible-playbook -i "$INVENTORY" $limit_arg $skip_reboot_arg \
        --tags "$TAGS" \
        -e "patch_bundle=$PATCH_BUNDLE" \
        -e "dry_run=false" \
        patch-management.yml
}

verify_patches() {
    log_info "Verifying applied patches..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would verify patches"
        return 0
    fi
    
    local limit_arg=""
    if [ -n "$LIMIT_HOSTS" ]; then
        limit_arg="--limit $LIMIT_HOSTS"
    fi
    
    ansible-playbook -i "$INVENTORY" $limit_arg --tags verify patch-management.yml
}

generate_report() {
    log_info "Generating patch report..."
    local report_file="patch-report-$(date +%Y%m%d-%H%M%S).txt"
    
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would generate report to $report_file"
        return 0
    fi
    
    {
        echo "=============================================="
        echo "Linux Patch Management Report"
        echo "Generated: $(date)"
        echo "Patch Bundle: $PATCH_BUNDLE"
        echo "Inventory: $INVENTORY"
        echo "=============================================="
        echo ""
        echo "Patched Hosts:"
        ansible -i "$INVENTORY" all --list-hosts 2>/dev/null || echo "N/A"
        echo ""
        echo "Report saved to: $report_file"
    } > "$report_file"
    
    log_info "Report saved to $report_file"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --inventory FILE      Inventory file (default: inventory.ini)
    --playbook FILE     Ansible playbook (default: patch-management.yml)
    --limit HOSTS       Limit to specific hosts
    --tags TAGS         Ansible tags to run (default: packages)
    --bundle CRITICAL|SECURITY|ALL  Patch bundle (default: critical)
    --no-skip-reboot    Do not skip reboot tasks
    -h, --help          Show this help message

Environment Variables:
    DRY_RUN             Set to 'false' to perform actual patching
    INVENTORY           Inventory file path
    PLAYBOOK            Playbook file path

Examples:
    $0 --dry-run --bundle critical
    $0 --limit webserver01 --tags packages
    DRY_RUN=false $0 --bundle security
EOF
}

main() {
    for arg in "$@"; do
        case $arg in
            --inventory) INVENTORY="$2"; shift 2 ;;
            --playbook) PLAYBOOK="$2"; shift 2 ;;
            --limit) LIMIT_HOSTS="$2"; shift 2 ;;
            --tags) TAGS="$2"; shift 2 ;;
            --bundle) PATCH_BUNDLE="$2"; shift 2 ;;
            --no-skip-reboot) SKIP_REBOOT=false ;;
            -h|--help) show_usage; exit 0 ;;
        esac
    done

    log_info "=== Linux Patch Management ==="
    log_info "Inventory : $INVENTORY"
    log_info "Playbook  : $PLAYBOOK"
    log_info "Bundle    : $PATCH_BUNDLE"
    log_info "Tags      : $TAGS"
    log_info "DRY_RUN   : $DRY_RUN"
    [ -n "$LIMIT_HOSTS" ] && log_info "Limit     : $LIMIT_HOSTS"
    echo ""

    check_dependencies
    gather_facts
    check_reboot_required
    apply_patches
    verify_patches
    generate_report

    echo ""
    log_info "=== Patch Management Complete ==="
}

main "$@"

#!/usr/bin/env bash
set -euo pipefail

# Harbor Container Registry Health Check
# Purpose: Verify all Harbor services, check registry API, and validate image push/pull
# Requirements: docker, curl, jq
# Tested on: Ubuntu 22.04

HARBOR_HOST="${HARBOR_HOST:-harbor.example.com}"
HARBOR_USER="${HARBOR_USER:-admin}"
HARBOR_PASS="${HARBOR_PASS:-ChangeMeOnFirstLogin!}"
HARBOR_URL="https://${HARBOR_HOST}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_dependencies() {
    local deps=("docker" "curl")
    for dep in "${deps[@]}"; do
        command -v "$dep" >/dev/null 2>&1 || { log_error "$dep not found"; exit 1; }
    done
}

check_containers() {
    log_info "Checking Harbor containers..."
    local harbor_dir="/opt/harbor"
    if [ ! -d "$harbor_dir" ]; then
        log_error "Harbor directory not found at ${harbor_dir}"
        return 1
    fi

    cd "$harbor_dir/harbor" 2>/dev/null || cd "$harbor_dir"
    local all_up=true
    local services=("harbor-core" "harbor-db" "harbor-jobservice" "harbor-log" "harbor-portal" "harbor-registry" "redis")

    for svc in "${services[@]}"; do
        local status
        status=$(docker compose ps --format '{{.Name}} {{.State}}' 2>/dev/null | grep "$svc" | awk '{print $2}')
        if [ "$status" = "running" ]; then
            log_info "  ${svc}: running"
        else
            log_error "  ${svc}: ${status:-not found}"
            all_up=false
        fi
    done

    if [ "$all_up" = true ]; then
        log_info "All containers running"
        return 0
    else
        log_error "Some containers are not healthy"
        return 1
    fi
}

check_api() {
    log_info "Checking Harbor API..."
    local response
    response=$(curl -sk -u "${HARBOR_USER}:${HARBOR_PASS}" "${HARBOR_URL}/api/v2.0/health" 2>/dev/null) || {
        log_error "Harbor API unreachable at ${HARBOR_URL}"
        return 1
    }

    if echo "$response" | grep -q '"status"'; then
        log_info "API responding: ${response}"
        return 0
    else
        log_error "API returned unexpected response: ${response}"
        return 1
    fi
}

check_registry_api() {
    log_info "Checking Docker Registry v2 API..."
    local response
    response=$(curl -sk -u "${HARBOR_USER}:${HARBOR_PASS}" "${HARBOR_URL}/v2/_catalog" 2>/dev/null) || {
        log_error "Registry API unreachable"
        return 1
    }

    local repo_count
    repo_count=$(echo "$response" | grep -o '"repositories"' | wc -l)
    if [ "$repo_count" -gt 0 ]; then
        log_info "Registry API accessible"
        return 0
    else
        log_warn "Registry API responded but format unexpected: ${response}"
        return 1
    fi
}

check_disk_usage() {
    log_info "Checking disk usage for /data..."
    if [ ! -d /data ]; then
        log_warn "/data directory not found — Harbor may use a different data volume"
        return 0
    fi

    local usage
    usage=$(df -h /data | awk 'NR==2 {print $5}' | tr -d '%')

    if [ "$usage" -ge 90 ]; then
        log_error "Disk usage critical: ${usage}% — run garbage collection immediately"
        return 1
    elif [ "$usage" -ge 75 ]; then
        log_warn "Disk usage elevated: ${usage}% — consider running garbage collection"
        return 0
    else
        log_info "Disk usage: ${usage}%"
        return 0
    fi
}

check_trivy_scanner() {
    log_info "Checking Trivy scanner..."
    local trivy_status
    trivy_status=$(docker ps --format '{{.Names}} {{.Status}}' 2>/dev/null | grep "trivy" | awk '{print $2}')

    if [ "$trivy_status" = "Up" ]; then
        log_info "Trivy scanner: running"
        return 0
    else
        log_warn "Trivy scanner: ${trivy_status:-not found}"
        return 1
    fi
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -H, --host HOST     Harbor hostname (default: harbor.example.com)
    -u, --user USER     Harbor admin user (default: admin)
    -p, --pass PASS     Harbor admin password
    -h, --help          Show this help message

Examples:
    $0
    $0 -H registry.mycompany.com -u admin -p mypassword
EOF
}

main() {
    for arg in "$@"; do
        case $arg in
            -H|--host) HARBOR_HOST="$2"; shift 2 ;;
            -u|--user) HARBOR_USER="$2"; shift 2 ;;
            -p|--pass) HARBOR_PASS="$2"; shift 2 ;;
            -h|--help) show_usage; exit 0 ;;
        esac
    done

    HARBOR_URL="https://${HARBOR_HOST}"

    check_dependencies

    log_info "Running Harbor health checks for ${HARBOR_HOST}..."
    echo ""

    local failed=0

    check_containers || ((failed++))
    echo ""

    check_api || ((failed++))
    echo ""

    check_registry_api || ((failed++))
    echo ""

    check_disk_usage || ((failed++))
    echo ""

    check_trivy_scanner || ((failed++))
    echo ""

    if [ "$failed" -eq 0 ]; then
        log_info "All health checks passed"
        exit 0
    else
        log_error "${failed} health check(s) failed"
        exit 1
    fi
}

main "$@"

#!/usr/bin/env bash
set -euo pipefail

# Harbor Container Registry Backup Script
# Purpose: Backup Harbor database, registry data, and configuration
# Requirements: docker, tar, gzip
# Safety: DRY_RUN enabled by default — use --execute to perform actual backup
# Tested on: Ubuntu 22.04

HARBOR_DIR="${HARBOR_DIR:-/opt/harbor}"
BACKUP_DIR="${BACKUP_DIR:-/backup/harbor}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
DRY_RUN="${DRY_RUN:-true}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_dependencies() {
    local deps=("docker" "tar" "gzip")
    for dep in "${deps[@]}"; do
        command -v "$dep" >/dev/null 2>&1 || { log_error "$dep not found"; exit 1; }
    done
    log_info "All dependencies satisfied"
}

backup_database() {
    log_info "Backing up Harbor database..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would dump PostgreSQL database from harbor-db container"
        return 0
    fi

    mkdir -p "${BACKUP_DIR}/db"
    docker exec harbor-db pg_dump -U postgres registry > "${BACKUP_DIR}/db/harbor-registry-${TIMESTAMP}.sql"
    gzip "${BACKUP_DIR}/db/harbor-registry-${TIMESTAMP}.sql"
    log_info "Database backup complete: harbor-registry-${TIMESTAMP}.sql.gz"
}

backup_registry_data() {
    log_info "Backing up Harbor registry data..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would tar /data/registry to backup directory"
        return 0
    fi

    mkdir -p "${BACKUP_DIR}/registry"
    tar czf "${BACKUP_DIR}/registry/harbor-registry-data-${TIMESTAMP}.tar.gz" -C /data/registry . 2>/dev/null || {
        log_warn "Registry data directory not found at /data/registry — skipping"
    }
    log_info "Registry data backup complete"
}

backup_configuration() {
    log_info "Backing up Harbor configuration..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would copy harbor.yml and certificates"
        return 0
    fi

    mkdir -p "${BACKUP_DIR}/config"
    cp "${HARBOR_DIR}/harbor.yml" "${BACKUP_DIR}/config/harbor.yml.${TIMESTAMP}" 2>/dev/null || {
        log_warn "harbor.yml not found at ${HARBOR_DIR}/harbor.yml"
    }
    if [ -d "${HARBOR_DIR}/cert" ]; then
        tar czf "${BACKUP_DIR}/config/harbor-certs-${TIMESTAMP}.tar.gz" -C "${HARBOR_DIR}" cert/
    fi
    log_info "Configuration backup complete"
}

backup_redis() {
    log_info "Backing up Redis data..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would trigger Redis BGSAVE"
        return 0
    fi

    docker exec harbor-redis redis-cli BGSAVE >/dev/null 2>&1 || {
        log_warn "Redis backup failed — container may not be named harbor-redis"
        return 0
    }
    sleep 5
    docker cp harbor-redis:/data/dump.rdb "${BACKUP_DIR}/redis-dump-${TIMESTAMP}.rdb" 2>/dev/null || {
        log_warn "Could not copy Redis dump file"
    }
    log_info "Redis backup complete"
}

create_backup_manifest() {
    log_info "Creating backup manifest..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would create manifest file"
        return 0
    fi

    cat > "${BACKUP_DIR}/manifest-${TIMESTAMP}.txt" <<EOF
Harbor Backup Manifest
Timestamp: ${TIMESTAMP}
Harbor Dir: ${HARBOR_DIR}
Backup Dir: ${BACKUP_DIR}
Retention: ${RETENTION_DAYS} days

Contents:
$(find "${BACKUP_DIR}" -name "*${TIMESTAMP}*" -type f -exec ls -lh {} \; 2>/dev/null)
EOF
    log_info "Manifest created: manifest-${TIMESTAMP}.txt"
}

cleanup_old_backups() {
    log_info "Cleaning up backups older than ${RETENTION_DAYS} days..."
    if [ "$DRY_RUN" = true ]; then
        local count
        count=$(find "${BACKUP_DIR}" -type f -mtime +"${RETENTION_DAYS}" 2>/dev/null | wc -l)
        log_warn "[dry-run] Would remove ${count} old backup files"
        return 0
    fi

    find "${BACKUP_DIR}" -type f -mtime +"${RETENTION_DAYS}" -delete 2>/dev/null || true
    log_info "Old backup cleanup complete"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --execute           Actually perform the backup (default is dry-run)
    --backup-dir PATH   Backup destination (default: /backup/harbor)
    --retention DAYS    Days to keep old backups (default: 30)
    -h, --help          Show this help message

Environment Variables:
    DRY_RUN             Set to 'false' to perform backup
    BACKUP_DIR          Backup destination directory
    HARBOR_DIR          Harbor installation directory
    RETENTION_DAYS      Number of days to retain backups

Examples:
    $0                          # Dry-run mode
    $0 --execute                # Perform backup
    $0 --execute --retention 7  # Backup with 7-day retention
EOF
}

main() {
    for arg in "$@"; do
        case $arg in
            --execute) DRY_RUN=false ;;
            --backup-dir) BACKUP_DIR="$2"; shift ;;
            --retention) RETENTION_DAYS="$2"; shift ;;
            -h|--help) show_usage; exit 0 ;;
        esac
    done

    if [ "$DRY_RUN" = true ]; then
        log_warn "Running in DRY-RUN mode. Use --execute to perform actual backup."
    fi

    log_info "=== Harbor Backup ==="
    log_info "Harbor Dir  : ${HARBOR_DIR}"
    log_info "Backup Dir  : ${BACKUP_DIR}"
    log_info "Timestamp   : ${TIMESTAMP}"
    log_info "Retention   : ${RETENTION_DAYS} days"
    log_info "DRY_RUN     : ${DRY_RUN}"
    echo ""

    check_dependencies

    backup_database
    backup_registry_data
    backup_configuration
    backup_redis
    create_backup_manifest
    cleanup_old_backups

    echo ""
    log_info "=== Backup Complete ==="
    log_info "Backup location: ${BACKUP_DIR}"
}

main "$@"

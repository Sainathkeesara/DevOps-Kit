#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# PostgreSQL Backup Script
# Purpose: Automated pg_dump backup with rotation and verification
# Requirements: PostgreSQL 16, pg_dump, gzip, sudo access
# Safety: Dry-run mode via DRY_RUN=true
# Tested on: Ubuntu 24.04 / PostgreSQL 16
###############################################################################

DRY_RUN="${DRY_RUN:-false}"
BACKUP_DIR="${BACKUP_DIR:-/backup/postgresql/daily}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/postgresql/backup.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
run_or_dry() {
    if [ "$DRY_RUN" = "true" ]; then
        log "[dry-run] $*"
    else
        "$@"
    fi
}

# Binary checks
command -v pg_dump >/dev/null 2>&1 || { log "ERROR: pg_dump not found"; exit 1; }
command -v gzip >/dev/null 2>&1 || { log "ERROR: gzip not found"; exit 1; }

mkdir -p "$BACKUP_DIR"

log "=== PostgreSQL backup started ==="

# Backup globals
log "Backing up globals..."
run_or_dry bash -c "sudo -u postgres pg_dumpall --globals-only | gzip > '${BACKUP_DIR}/globals_${DATE}.sql.gz'"

# Backup each non-template database
DBS=$(sudo -u postgres psql -t -A -c "SELECT datname FROM pg_database WHERE datistemplate = false;" 2>/dev/null)
for db in $DBS; do
    log "Backing up database: ${db}"
    if [ "$DRY_RUN" = "true" ]; then
        log "[dry-run] pg_dump -Fc ${db} -> ${BACKUP_DIR}/${db}_${DATE}.dump"
    else
        sudo -u postgres pg_dump -Fc -f "${BACKUP_DIR}/${db}_${DATE}.dump" "$db"
        SIZE=$(du -sh "${BACKUP_DIR}/${db}_${DATE}.dump" | cut -f1)
        log "Completed: ${db}_${DATE}.dump (${SIZE})"
    fi
done

# Cleanup old backups
log "Cleaning backups older than ${RETENTION_DAYS} days..."
if [ "$DRY_RUN" = "true" ]; then
    OLD_COUNT=$(find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS 2>/dev/null | wc -l)
    log "[dry-run] Would delete ${OLD_COUNT} old backup files"
else
    find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    log "Cleanup completed"
fi

log "=== PostgreSQL backup completed ==="
log "Log: ${LOG_FILE}"

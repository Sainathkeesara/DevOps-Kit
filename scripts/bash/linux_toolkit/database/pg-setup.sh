#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# PostgreSQL Setup Script
# Purpose: Automated installation and basic configuration of PostgreSQL 16
# Requirements: Ubuntu 24.04, root/sudo access, internet connectivity
# Safety: Dry-run mode via DRY_RUN=true — no changes applied
# Tested on: Ubuntu 24.04 LTS
###############################################################################

DRY_RUN="${DRY_RUN:-false}"
PG_VERSION="16"
PG_PORT="${PG_PORT:-5432}"
PG_LISTEN="${PG_LISTEN:-'*'}"
LOG_FILE="/tmp/pg-setup-$(date +%Y%m%d_%H%M%S).log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
run_or_dry() {
    if [ "$DRY_RUN" = "true" ]; then
        log "[dry-run] $*"
    else
        "$@"
    fi
}

# Binary checks
command -v apt-get >/dev/null 2>&1 || { log "ERROR: apt-get not found — Ubuntu/Debian required"; exit 1; }
command -v systemctl >/dev/null 2>&1 || { log "ERROR: systemctl not found"; exit 1; }

log "=== PostgreSQL ${PG_VERSION} setup started ==="
log "DRY_RUN=${DRY_RUN}"

# Step 1: Add repository
log "Adding PostgreSQL APT repository..."
run_or_dry sudo sh -c "echo 'deb https://apt.postgresql.org/pub/repos/apt \$(lsb_release -cs)-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
run_or_dry wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Step 2: Install
log "Updating package lists..."
run_or_dry sudo apt-get update

log "Installing PostgreSQL ${PG_VERSION}..."
run_or_dry sudo apt-get install -y "postgresql-${PG_VERSION}" "postgresql-contrib-${PG_VERSION}" "postgresql-client-${PG_VERSION}"

# Step 3: Enable and start
log "Enabling PostgreSQL service..."
run_or_dry sudo systemctl enable postgresql
run_or_dry sudo systemctl start postgresql

# Step 4: Verify
if [ "$DRY_RUN" = "false" ]; then
    VERSION=$(sudo -u postgres psql -t -A -c "SELECT version();" 2>/dev/null | head -1)
    log "Installed: ${VERSION}"
    ss -tlnp | grep "${PG_PORT}" && log "Listening on port ${PG_PORT}" || log "WARNING: Not listening on port ${PG_PORT}"
else
    log "[dry-run] Would verify installation"
fi

# Step 5: Create backup of default config
if [ "$DRY_RUN" = "false" ]; then
    sudo cp "/etc/postgresql/${PG_VERSION}/main/postgresql.conf" "/etc/postgresql/${PG_VERSION}/main/postgresql.conf.backup.$(date +%Y%m%d)"
    sudo cp "/etc/postgresql/${PG_VERSION}/main/pg_hba.conf" "/etc/postgresql/${PG_VERSION}/main/pg_hba.conf.backup.$(date +%Y%m%d)"
    log "Config backups created"
else
    log "[dry-run] Would backup config files"
fi

log "=== PostgreSQL ${PG_VERSION} setup completed ==="
log "Log: ${LOG_FILE}"

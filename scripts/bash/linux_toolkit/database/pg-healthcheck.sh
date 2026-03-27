#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# PostgreSQL Health Check Script
# Purpose: Check PostgreSQL service health — exit 0 healthy, exit 1 unhealthy
# Requirements: PostgreSQL 16, psql, sudo access
# Safety: Read-only — no modifications made
# Tested on: Ubuntu 24.04 / PostgreSQL 16
###############################################################################

ERRORS=0

# Check 1: PostgreSQL process running
if ! pgrep -x postgres > /dev/null 2>&1; then
    echo "CRITICAL: postgres process not found"
    ((ERRORS++))
fi

# Check 2: Can connect
if ! sudo -u postgres psql -c "SELECT 1;" > /dev/null 2>&1; then
    echo "CRITICAL: cannot connect to PostgreSQL"
    ((ERRORS++))
fi

# Check 3: Replication lag (if replicas exist)
LAG=$(sudo -u postgres psql -t -A -c "SELECT COALESCE(MAX(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)), 0) FROM pg_stat_replication;" 2>/dev/null || echo "0")
if [ "${LAG:-0}" -gt 104857600 ]; then
    echo "WARN: replication lag at ${LAG} bytes (>100MB)"
    ((ERRORS++))
fi

# Check 4: Connection usage
CONN=$(sudo -u postgres psql -t -A -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null || echo "0")
MAX_CONN=$(sudo -u postgres psql -t -A -c "SHOW max_connections;" 2>/dev/null || echo "100")
if [ "$MAX_CONN" -gt 0 ]; then
    USAGE=$((CONN * 100 / MAX_CONN))
    if [ "$USAGE" -ge 80 ]; then
        echo "WARN: connection usage at ${USAGE}% (${CONN}/${MAX_CONN})"
        ((ERRORS++))
    fi
fi

# Check 5: Data directory disk space
DATA_DIR="/var/lib/postgresql/16/main"
if [ -d "$DATA_DIR" ]; then
    DISK_USAGE=$(df "$DATA_DIR" --output=pcent 2>/dev/null | tail -1 | tr -d '% ' || echo "0")
    if [ "${DISK_USAGE:-0}" -ge 90 ]; then
        echo "WARN: data directory disk usage at ${DISK_USAGE}%"
        ((ERRORS++))
    fi
fi

# Check 6: WAL archiver status
FAILED_WAL=$(sudo -u postgres psql -t -A -c "SELECT last_failed_wal FROM pg_stat_archiver;" 2>/dev/null || echo "")
if [ -n "$FAILED_WAL" ] && [ "$FAILED_WAL" != "" ]; then
    LAST_OK=$(sudo -u postgres psql -t -A -c "SELECT last_archived_wal FROM pg_stat_archiver;" 2>/dev/null || echo "")
    if [ -n "$LAST_OK" ] && [[ "$FAILED_WAL" > "$LAST_OK" ]]; then
        echo "WARN: WAL archiving has failures — last failed: ${FAILED_WAL}"
        ((ERRORS++))
    fi
fi

if [ "$ERRORS" -gt 0 ]; then
    echo "UNHEALTHY: ${ERRORS} error(s)"
    exit 1
fi

echo "HEALTHY"
exit 0

# Project: Production PostgreSQL Database Server on Linux

## Purpose

Walk through building a production-grade PostgreSQL database server on Ubuntu 24.04 with streaming replication, automated backups, connection pooling, monitoring, and security hardening. This project covers a single primary server with optional read replicas, suitable for SRE and DevOps teams managing stateful workloads.

## When to Use

Use this project when you need to:
- Deploy PostgreSQL as a backend database for applications on Linux
- Set up streaming replication for high availability and read scaling
- Implement automated backup and point-in-time recovery (PITR)
- Harden PostgreSQL against common attack vectors
- Monitor database health with Prometheus metrics

## Prerequisites

### System Requirements
- **OS**: Ubuntu 24.04 LTS (primary) or RHEL 9+ (adapt package commands)
- **CPU**: 2+ cores (4+ recommended for replication workloads)
- **RAM**: 4GB minimum, 8GB recommended (tune `shared_buffers` to ~25% of RAM)
- **Disk**: 50GB+ for data, separate disk/volume recommended for WAL and backups
- **Network**: Static IP, port 5432 open between primary and replicas

### Software Requirements
- PostgreSQL 16 (`postgresql`, `postgresql-contrib`)
- `pgbackrest` or `pg_dump` for backups
- `pgbouncer` for connection pooling
- `prometheus-postgres-exporter` for metrics
- `rsync` for WAL shipping (if not using streaming replication)

### Knowledge Prerequisites
- Linux system administration (systemd, users, file permissions)
- Basic SQL (CREATE DATABASE, CREATE USER, GRANT)
- Understanding of client-server database architecture
- Network basics (firewall, ports, DNS)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    PostgreSQL Primary (Ubuntu 24.04)             │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐ │
│  │  PostgreSQL   │  │  PgBouncer   │  │  pgBackRest /         │ │
│  │  16 (primary) │  │  (pooler)    │  │  pg_dump (backups)    │ │
│  │  port 5432    │  │  port 6432   │  │  /backup/postgresql/  │ │
│  └──────┬───────┘  └──────┬───────┘  └───────────┬───────────┘ │
│         │                 │                       │             │
│  ┌──────┴─────────────────┴───────────────────────┴───────────┐ │
│  │  Monitoring (postgres_exporter) | Firewall (ufw)           │ │
│  │  SSL/TLS (server.crt/key)      | pg_hba.conf (auth)       │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────┬───────────────────────────────────┘
                              │ streaming replication (port 5432)
                    ┌─────────┴─────────┐
                    │                   │
           ┌────────┴───────┐  ┌────────┴───────┐
           │  Replica 1     │  │  Replica 2     │
           │  (hot standby) │  │  (hot standby) │
           │  read-only     │  │  read-only     │
           └────────────────┘  └────────────────┘
```

## Phases

| Phase | Description | Time |
|-------|-------------|------|
| 1 | Install and configure PostgreSQL 16 primary | 30 min |
| 2 | Database and user management | 20 min |
| 3 | SSL/TLS encryption | 20 min |
| 4 | Connection pooling with PgBouncer | 25 min |
| 5 | Streaming replication (read replicas) | 30 min |
| 6 | Automated backups with pg_dump and pgBackRest | 30 min |
| 7 | Monitoring with Prometheus postgres_exporter | 20 min |
| 8 | Security hardening | 25 min |
| 9 | Disaster recovery drill | 20 min |
| 10 | Performance tuning baseline | 15 min |

---

## Phase 1: Install and Configure PostgreSQL 16 Primary

### Step 1.1: Install PostgreSQL 16

```bash
# Add PostgreSQL APT repository
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

sudo apt update
sudo apt install -y postgresql-16 postgresql-contrib-16 postgresql-client-16
```

Verify:
```bash
sudo -u postgres psql -c "SELECT version();"
# Expected: PostgreSQL 16.x on ...
```

### Step 1.2: Initialize and start the service

```bash
# PostgreSQL is auto-initialized on install via apt
sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo systemctl status postgresql
```

### Step 1.3: Configure postgresql.conf

```bash
sudo cp /etc/postgresql/16/main/postgresql.conf /etc/postgresql/16/main/postgresql.conf.backup.$(date +%Y%m%d)

sudo tee /etc/postgresql/16/main/postgresql.conf > /dev/null <<'CONF'
# Connection
listen_addresses = '*'
port = 5432
max_connections = 100

# Memory (tune to ~25% of system RAM)
shared_buffers = 2GB
effective_cache_size = 6GB
work_mem = 16MB
maintenance_work_mem = 512MB

# WAL
wal_level = replica
max_wal_senders = 5
wal_keep_size = 1GB
max_replication_slots = 5

# Logging
log_destination = 'stderr'
logging_collector = on
log_directory = '/var/log/postgresql'
log_filename = 'postgresql-%Y-%m-%d.log'
log_rotation_age = 1d
log_rotation_size = 100MB
log_min_duration_statement = 1000
log_line_prefix = '%m [%p] %u@%d '
log_statement = 'ddl'

# SSL
ssl = on
ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'

# Performance
random_page_cost = 1.1
effective_io_concurrency = 200
huge_pages = try
CONF
```

### Step 1.4: Configure pg_hba.conf for authentication

```bash
sudo cp /etc/postgresql/16/main/pg_hba.conf /etc/postgresql/16/main/pg_hba.conf.backup.$(date +%Y%m%d)

sudo tee /etc/postgresql/16/main/pg_hba.conf > /dev/null <<'CONF'
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Local connections
local   all             postgres                                peer
local   all             all                                     peer

# IPv4 local connections
host    all             all             127.0.0.1/32            scram-sha-256

# IPv4 LAN connections (adjust CIDR to your network)
host    all             app_user        192.168.1.0/24          scram-sha-256

# Replication connections
host    replication     replicator      192.168.1.0/24          scram-sha-256

# Reject everything else
host    all             all             0.0.0.0/0               reject
CONF
```

### Step 1.5: Restart and verify

```bash
sudo systemctl restart postgresql

# Verify listening
ss -tlnp | grep 5432

# Verify config loaded
sudo -u postgres psql -c "SHOW listen_addresses;"
sudo -u postgres psql -c "SHOW wal_level;"
```

---

## Phase 2: Database and User Management

### Step 2.1: Create application database

```bash
sudo -u postgres psql <<'SQL'
CREATE DATABASE appdb;
CREATE USER app_user WITH PASSWORD 'StrongP@ss2026!';
GRANT CONNECT ON DATABASE appdb TO app_user;
\c appdb
GRANT USAGE ON SCHEMA public TO app_user;
GRANT CREATE ON SCHEMA public TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO app_user;
SQL
```

### Step 2.2: Create read-only user for replicas

```bash
sudo -u postgres psql <<'SQL'
CREATE USER readonly_user WITH PASSWORD 'ReadOnlyP@ss2026!';
GRANT CONNECT ON DATABASE appdb TO readonly_user;
\c appdb
GRANT USAGE ON SCHEMA public TO readonly_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly_user;
SQL
```

### Step 2.3: Create replication user

```bash
sudo -u postgres psql <<'SQL'
CREATE USER replicator WITH REPLICATION LOGIN PASSWORD 'ReplP@ss2026!';
SQL
```

### Step 2.4: Verify user access

```bash
# Test app_user connection
PGPASSWORD='StrongP@ss2026!' psql -h localhost -U app_user -d appdb -c "SELECT current_user;"

# Test readonly_user
PGPASSWORD='ReadOnlyP@ss2026!' psql -h localhost -U readonly_user -d appdb -c "SELECT current_user;"

# List all users
sudo -u postgres psql -c "\du"
```

---

## Phase 3: SSL/TLS Encryption

### Step 3.1: Generate self-signed certificates (production: use CA-signed)

```bash
sudo mkdir -p /etc/postgresql/ssl
sudo openssl req -new -x509 -days 365 -nodes \
  -out /etc/postgresql/ssl/server.crt \
  -keyout /etc/postgresql/ssl/server.key \
  -subj "/CN=postgres-primary"
sudo chown postgres:postgres /etc/postgresql/ssl/server.*
sudo chmod 600 /etc/postgresql/ssl/server.key
```

### Step 3.2: Update postgresql.conf for SSL

```bash
sudo sed -i "s|ssl_cert_file = .*|ssl_cert_file = '/etc/postgresql/ssl/server.crt'|" /etc/postgresql/16/main/postgresql.conf
sudo sed -i "s|ssl_key_file = .*|ssl_key_file = '/etc/postgresql/ssl/server.key'|" /etc/postgresql/16/main/postgresql.conf
```

### Step 3.3: Force SSL for remote connections

Add to `pg_hba.conf` (replace existing LAN host line):
```
hostssl all  app_user  192.168.1.0/24  scram-sha-256
```

### Step 3.4: Restart and verify SSL

```bash
sudo systemctl restart postgresql

# Verify SSL is active
sudo -u postgres psql -c "SHOW ssl;"
# Expected: on

# Test SSL connection
PGPASSWORD='StrongP@ss2026!' psql "host=localhost dbname=appdb user=app_user sslmode=require" -c "SELECT current_setting('ssl_is_active');"
```

---

## Phase 4: Connection Pooling with PgBouncer

### Step 4.1: Install PgBouncer

```bash
sudo apt install -y pgbouncer
```

### Step 4.2: Configure PgBouncer

```bash
sudo cp /etc/pgbouncer/pgbouncer.ini /etc/pgbouncer/pgbouncer.ini.backup.$(date +%Y%m%d)

sudo tee /etc/pgbouncer/pgbouncer.ini > /dev/null <<'CONF'
[databases]
appdb = host=127.0.0.1 port=5432 dbname=appdb

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 6432
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt

# Pool settings
pool_mode = transaction
default_pool_size = 20
min_pool_size = 5
reserve_pool_size = 5
reserve_pool_timeout = 3
max_client_conn = 200
max_db_connections = 50

# Logging
log_connections = 1
log_disconnections = 1
log_pooler_errors = 1
stats_period = 60

# Admin
admin_users = postgres
stats_users = postgres
CONF
```

### Step 4.3: Set up PgBouncer authentication

```bash
# Generate MD5 hashes for PgBouncer (it uses md5 internally)
APP_HASH=$(sudo -u postgres psql -t -A -c "SELECT rolpassword FROM pg_authid WHERE rolname = 'app_user';")

sudo tee /etc/pgbouncer/userlist.txt > /dev/null <<EOF
"app_user" "$APP_HASH"
"postgres" "$APP_HASH"
EOF

sudo chmod 640 /etc/pgbouncer/userlist.txt
sudo chown postgres:postgres /etc/pgbouncer/userlist.txt
```

### Step 4.4: Start and verify PgBouncer

```bash
sudo systemctl enable pgbouncer
sudo systemctl start pgbouncer

# Test connection through PgBouncer
PGPASSWORD='StrongP@ss2026!' psql -h localhost -p 6432 -U app_user -d appdb -c "SELECT current_user;"

# Check PgBouncer stats
sudo -u postgres psql -h localhost -p 6432 -U postgres pgbouncer -c "SHOW POOLS;"
sudo -u postgres psql -h localhost -p 6432 -U postgres pgbouncer -c "SHOW STATS;"
```

---

## Phase 5: Streaming Replication (Read Replicas)

### Step 5.1: Configure replication slot on primary

```bash
sudo -u postgres psql -c "SELECT pg_create_physical_replication_slot('replica1_slot');"
sudo -u postgres psql -c "SELECT * FROM pg_replication_slots;"
```

### Step 5.2: Prepare replica server (run on replica machine)

```bash
# Install PostgreSQL 16 on replica
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
sudo apt install -y postgresql-16 postgresql-client-16

# Stop PostgreSQL on replica
sudo systemctl stop postgresql

# Clear default data directory
sudo -u postgres rm -rf /var/lib/postgresql/16/main/*

# Create .pgpass for replication credentials
echo "PRIMARY_IP:5432:replication:replicator:ReplP@ss2026!" | sudo -u postgres tee ~postgres/.pgpass > /dev/null
sudo -u postgres chmod 600 ~postgres/.pgpass
```

### Step 5.3: Base backup from primary to replica

```bash
# Run on replica
PRIMARY_IP="192.168.1.100"  # Replace with actual primary IP
sudo -u postgres pg_basebackup \
  -h "$PRIMARY_IP" \
  -U replicator \
  -D /var/lib/postgresql/16/main \
  -Fp -Xs -P -R \
  -S replica1_slot
```

### Step 5.4: Verify standby.signal and connection info

```bash
# The -R flag auto-creates standby.signal and populates postgresql.auto.conf
sudo -u postgres cat /var/lib/postgresql/16/main/standby.signal
sudo -u postgres cat /var/lib/postgresql/16/main/postgresql.auto.conf

# Start replica
sudo systemctl start postgresql
```

### Step 5.5: Verify replication status

On primary:
```bash
sudo -u postgres psql -c "SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn FROM pg_stat_replication;"
sudo -u postgres psql -c "SELECT slot_name, active FROM pg_replication_slots;"
```

On replica:
```bash
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
# Expected: t (true = standby mode)
```

---

## Phase 6: Automated Backups

### Step 6.1: Create backup directory

```bash
sudo mkdir -p /backup/postgresql/{daily,weekly,wal_archive}
sudo chown -R postgres:postgres /backup/postgresql
```

### Step 6.2: Configure WAL archiving

Add to `postgresql.conf`:
```bash
sudo tee -a /etc/postgresql/16/main/postgresql.conf > /dev/null <<'CONF'

# WAL Archiving
archive_mode = on
archive_command = 'cp %p /backup/postgresql/wal_archive/%f'
archive_timeout = 300
CONF

sudo systemctl restart postgresql
```

### Step 6.3: Create pg_dump backup script

```bash
sudo tee /usr/local/bin/pg-backup.sh > /dev/null <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# PostgreSQL Backup — pg_dump with rotation
# Purpose: Daily logical backup of all databases with retention
# Requirements: pg_dump, pg_dumpall, gzip
# Safety: Dry-run mode via DRY_RUN=true
# Tested on: Ubuntu 24.04 / PostgreSQL 16
###############################################################################

DRY_RUN="${DRY_RUN:-false}"
BACKUP_DIR="/backup/postgresql/daily"
RETENTION_DAYS=30
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/postgresql/backup.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

command -v pg_dump >/dev/null 2>&1 || { log "ERROR: pg_dump not found"; exit 1; }
command -v gzip >/dev/null 2>&1 || { log "ERROR: gzip not found"; exit 1; }

mkdir -p "$BACKUP_DIR"

log "=== PostgreSQL backup started ==="

if [ "$DRY_RUN" = "true" ]; then
    log "[dry-run] Would dump all databases to $BACKUP_DIR/"
    log "[dry-run] Would dump globals to $BACKUP_DIR/globals_${DATE}.sql.gz"
    log "[dry-run] Would clean files older than $RETENTION_DAYS days"
    log "=== PostgreSQL backup completed (dry-run) ==="
    exit 0
fi

# Backup globals (roles, tablespaces)
sudo -u postgres pg_dumpall --globals-only | gzip > "$BACKUP_DIR/globals_${DATE}.sql.gz"
log "Globals backup: globals_${DATE}.sql.gz"

# Backup each database
for db in $(sudo -u postgres psql -t -A -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';"); do
    log "Backing up database: $db"
    sudo -u postgres pg_dump -Fc -f "$BACKUP_DIR/${db}_${DATE}.dump" "$db"
    log "Completed: ${db}_${DATE}.dump ($(du -sh "$BACKUP_DIR/${db}_${DATE}.dump" | cut -f1))"
done

# Cleanup old backups
find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
log "Cleaned backups older than $RETENTION_DAYS days"

log "=== PostgreSQL backup completed ==="
SCRIPT

sudo chmod +x /usr/local/bin/pg-backup.sh
```

### Step 6.4: Schedule backups

```bash
# Daily at 2 AM
echo '0 2 * * * postgres /usr/local/bin/pg-backup.sh >> /var/log/postgresql/backup.log 2>&1' | \
  sudo tee /etc/cron.d/pg-backup
sudo chmod 0644 /etc/cron.d/pg-backup
```

### Step 6.5: Test backup

```bash
# Dry-run
sudo DRY_RUN=true /usr/local/bin/pg-backup.sh

# Actual run
sudo /usr/local/bin/pg-backup.sh

# Verify backup files
ls -la /backup/postgresql/daily/
```

### Step 6.6: Point-in-time recovery test

```bash
# Record current time
sudo -u postgres psql -c "SELECT now();"

# Simulate data insertion
sudo -u postgres psql -d appdb -c "CREATE TABLE test_backup(id serial PRIMARY KEY, ts timestamp DEFAULT now());"
sudo -u postgres psql -d appdb -c "INSERT INTO test_backup DEFAULT VALUES;"

# Record WAL position
sudo -u postgres psql -c "SELECT pg_current_wal_lsn();"

# Simulate disaster
sudo -u postgres psql -d appdb -c "DROP TABLE test_backup;"

# Recovery: restore from backup
pg_restore -h localhost -U postgres -d appdb /backup/postgresql/daily/appdb_*.dump 2>/dev/null || true

# Verify
sudo -u postgres psql -d appdb -c "\dt"
```

---

## Phase 7: Monitoring with Prometheus

### Step 7.1: Install postgres_exporter

```bash
EXPORTER_VERSION="0.15.0"
wget "https://github.com/prometheus-community/postgres_exporter/releases/download/v${EXPORTER_VERSION}/postgres_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz"
tar xzf "postgres_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz"
sudo cp "postgres_exporter-${EXPORTER_VERSION}.linux-amd64/postgres_exporter" /usr/local/bin/
sudo chmod +x /usr/local/bin/postgres_exporter
rm -rf "postgres_exporter-${EXPORTER_VERSION}.linux-amd64"*
```

### Step 7.2: Create exporter data source user

```bash
sudo -u postgres psql <<'SQL'
CREATE USER exporter WITH PASSWORD 'ExporterP@ss2026!' LOGIN;
GRANT pg_monitor TO exporter;
SQL
```

### Step 7.3: Create systemd service

```bash
sudo tee /etc/systemd/system/postgres-exporter.service > /dev/null <<'CONF'
[Unit]
Description=Prometheus PostgreSQL Exporter
After=postgresql.service

[Service]
Type=simple
User=nobody
Environment="DATA_SOURCE_NAME=postgresql://exporter:ExporterP@ss2026!@localhost:5432/appdb?sslmode=disable"
ExecStart=/usr/local/bin/postgres_exporter --web.listen-address=:9187
Restart=always

[Install]
WantedBy=multi-user.target
CONF

sudo systemctl daemon-reload
sudo systemctl enable postgres-exporter
sudo systemctl start postgres-exporter
```

### Step 7.4: Verify metrics

```bash
# Check exporter is running
ss -tlnp | grep 9187

# View metrics
curl -s http://localhost:9187/metrics | grep -E '^pg_' | head -20

# Key metrics to monitor:
# pg_stat_activity_count — active connections
# pg_stat_replication_lag_bytes — replication lag
# pg_database_size_bytes — database size
# pg_stat_bgwriter_buffers_checkpoint — checkpoint activity
```

### Step 7.5: Create health check script

```bash
sudo tee /usr/local/bin/pg-healthcheck.sh > /dev/null <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

# Purpose: PostgreSQL health check — exit 0 healthy, exit 1 unhealthy

ERRORS=0

# Check PostgreSQL process
if ! pgrep -x postgres > /dev/null; then
    echo "CRITICAL: postgres not running"
    ((ERRORS++))
fi

# Check can connect
if ! sudo -u postgres psql -c "SELECT 1;" > /dev/null 2>&1; then
    echo "CRITICAL: cannot connect to PostgreSQL"
    ((ERRORS++))
fi

# Check replication lag (if replicas exist)
LAG=$(sudo -u postgres psql -t -A -c "SELECT COALESCE(MAX(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)), 0) FROM pg_stat_replication;" 2>/dev/null || echo "0")
if [ "${LAG:-0}" -gt 104857600 ]; then  # 100MB
    echo "WARN: replication lag at ${LAG} bytes"
    ((ERRORS++))
fi

# Check connection count vs max
CONN=$(sudo -u postgres psql -t -A -c "SELECT count(*) FROM pg_stat_activity;")
MAX_CONN=$(sudo -u postgres psql -t -A -c "SHOW max_connections;")
USAGE=$((CONN * 100 / MAX_CONN))
if [ "$USAGE" -ge 80 ]; then
    echo "WARN: connection usage at ${USAGE}% (${CONN}/${MAX_CONN})"
    ((ERRORS++))
fi

# Check disk space on data directory
DATA_DIR="/var/lib/postgresql/16/main"
USAGE_DISK=$(df "$DATA_DIR" --output=pcent | tail -1 | tr -d '% ')
if [ "$USAGE_DISK" -ge 90 ]; then
    echo "WARN: data directory disk usage at ${USAGE_DISK}%"
    ((ERRORS++))
fi

if [ "$ERRORS" -gt 0 ]; then
    echo "UNHEALTHY: $ERRORS error(s)"
    exit 1
fi

echo "HEALTHY"
exit 0
SCRIPT

sudo chmod +x /usr/local/bin/pg-healthcheck.sh
```

### Step 7.6: Schedule health checks

```bash
# Run health check every minute
echo '* * * * * postgres /usr/local/bin/pg-healthcheck.sh >> /var/log/postgresql/healthcheck.log 2>&1' | \
  sudo tee /etc/cron.d/pg-healthcheck
```

---

## Phase 8: Security Hardening

### Step 8.1: Firewall configuration

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow from 192.168.1.0/24 to any port 5432 proto tcp comment "PostgreSQL"
sudo ufw allow from 192.168.1.0/24 to any port 6432 proto tcp comment "PgBouncer"
sudo ufw allow from 192.168.1.0/24 to any port 9187 proto tcp comment "Postgres Exporter"
sudo ufw --force enable
sudo ufw status verbose
```

### Step 8.2: Restrict superuser access

```bash
sudo -u postgres psql <<'SQL'
-- Remove CREATEDB and CREATEROLE from app_user
ALTER USER app_user NOCREATEDB NOCREATEROLE;

-- Ensure postgres user requires password for network access
ALTER USER postgres PASSWORD 'PostgresAdminP@ss2026!';

-- Revoke public schema access from PUBLIC
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
SQL
```

### Step 8.3: Enable audit logging

Add to `postgresql.conf`:
```bash
sudo tee -a /etc/postgresql/16/main/postgresql.conf > /dev/null <<'CONF'

# Audit logging
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0
log_autovacuum_min_duration = 0
CONF

sudo systemctl reload postgresql
```

### Step 8.4: Configure row-level security (example)

```bash
sudo -u postgres psql -d appdb <<'SQL'
-- Example: enable RLS on a sensitive table
CREATE TABLE sensitive_data (
    id serial PRIMARY KEY,
    department text NOT NULL,
    data text NOT NULL,
    created_at timestamp DEFAULT now()
);

ALTER TABLE sensitive_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY dept_isolation ON sensitive_data
    FOR ALL
    USING (department = current_setting('app.department', true));

-- Test: set department context
SET app.department = 'engineering';
SELECT * FROM sensitive_data;  -- Only sees engineering rows
SQL
```

### Step 8.5: File permissions audit

```bash
# Verify data directory permissions
sudo ls -la /var/lib/postgresql/16/main/ | head -5
# Expected: owned by postgres:postgres, mode 0700

# Verify config files
sudo ls -la /etc/postgresql/16/main/*.conf
# Expected: owned by postgres:postgres, mode 0640

# Verify SSL key
sudo ls -la /etc/postgresql/ssl/server.key
# Expected: owned by postgres:postgres, mode 0600

# Verify backup permissions
sudo ls -la /backup/postgresql/
# Expected: owned by postgres:postgres
```

---

## Phase 9: Disaster Recovery Drill

### Step 9.1: Simulate primary failure

```bash
# On primary — stop PostgreSQL
sudo systemctl stop postgresql

# Verify replica detects the failure
# On replica:
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
# Still returns 't' — replica is in standby mode
```

### Step 9.2: Promote replica to primary

```bash
# On replica:
sudo -u postgres pg_ctl promote -D /var/lib/postgresql/16/main

# Verify promotion
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
# Expected: f (false = now primary)

# Verify it accepts writes
sudo -u postgres psql -d appdb -c "CREATE TABLE dr_test(id serial); INSERT INTO dr_test DEFAULT VALUES; SELECT * FROM dr_test;"
```

### Step 9.3: Restore original primary as replica

```bash
# On original primary (now down):
sudo -u postgres rm -rf /var/lib/postgresql/16/main/*

# Base backup from new primary
sudo -u postgres pg_basebackup \
  -h NEW_PRIMARY_IP \
  -U replicator \
  -D /var/lib/postgresql/16/main \
  -Fp -Xs -P -R \
  -S replica2_slot

sudo systemctl start postgresql

# Verify it's now a standby
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
# Expected: t
```

### Step 9.4: Verify data consistency

```bash
# On both servers — compare row count
sudo -u postgres psql -d appdb -c "SELECT count(*) FROM dr_test;"
# Should match on both
```

---

## Phase 10: Performance Tuning Baseline

### Step 10.1: Apply pgtune recommendations

```bash
# Install pgtune
sudo apt install -y pgtune

# Generate recommendations (do not auto-apply)
pgtune --input-config /etc/postgresql/16/main/postgresql.conf \
  --output-config /tmp/postgresql-tuned.conf \
  --type Web \
  --connections 100

# Review differences
diff /etc/postgresql/16/main/postgresql.conf /tmp/postgresql-tuned.conf
```

### Step 10.2: Create performance baseline script

```bash
sudo tee /usr/local/bin/pg-baseline.sh > /dev/null <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

echo "=== PostgreSQL Performance Baseline ==="
echo "Generated: $(date)"
echo ""

echo "--- Connection Stats ---"
sudo -u postgres psql -c "SELECT count(*) as total_connections, 
  count(*) FILTER (WHERE state = 'active') as active,
  count(*) FILTER (WHERE state = 'idle') as idle,
  count(*) FILTER (WHERE state = 'idle in transaction') as idle_in_transaction
FROM pg_stat_activity;"

echo ""
echo "--- Database Sizes ---"
sudo -u postgres psql -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) as size 
FROM pg_database ORDER BY pg_database_size(datname) DESC;"

echo ""
echo "--- Cache Hit Ratio ---"
sudo -u postgres psql -c "SELECT 
  sum(heap_blks_read) as heap_read,
  sum(heap_blks_hit) as heap_hit,
  round(sum(heap_blks_hit) * 100.0 / nullif(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2) as cache_hit_ratio
FROM pg_statio_user_tables;"

echo ""
echo "--- Index Usage ---"
sudo -u postgres psql -c "SELECT 
  schemaname, relname,
  seq_scan, idx_scan,
  CASE WHEN seq_scan + idx_scan > 0 
    THEN round(idx_scan * 100.0 / (seq_scan + idx_scan), 2) 
    ELSE 0 END as idx_usage_pct
FROM pg_stat_user_tables 
ORDER BY seq_scan DESC LIMIT 10;"

echo ""
echo "--- Replication Status ---"
sudo -u postgres psql -c "SELECT client_addr, state, 
  pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn) as send_lag_bytes,
  pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) as replay_lag_bytes
FROM pg_stat_replication;"

echo ""
echo "--- Long Running Queries (>5s) ---"
sudo -u postgres psql -c "SELECT pid, now() - pg_stat_activity.query_start AS duration, query, state
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 seconds'
AND state != 'idle'
ORDER BY duration DESC;"

echo ""
echo "=== Baseline Complete ==="
SCRIPT

sudo chmod +x /usr/local/bin/pg-baseline.sh
```

### Step 10.3: Run baseline

```bash
sudo /usr/local/bin/pg-baseline.sh
```

---

## Verify

### End-to-End Verification Checklist

```bash
# 1. PostgreSQL running
systemctl is-active postgresql

# 2. Can connect
sudo -u postgres psql -c "SELECT version();" | head -1

# 3. App user can access appdb
PGPASSWORD='StrongP@ss2026!' psql -h localhost -U app_user -d appdb -c "SELECT current_user, current_database();"

# 4. SSL active
sudo -u postgres psql -c "SHOW ssl;" | grep on

# 5. PgBouncer running
systemctl is-active pgbouncer
PGPASSWORD='StrongP@ss2026!' psql -h localhost -p 6432 -U app_user -d appdb -c "SELECT 1;"

# 6. Replication active (if replicas configured)
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_replication;"

# 7. Backups exist
ls /backup/postgresql/daily/ | head -5

# 8. WAL archiving working
sudo -u postgres psql -c "SELECT archive_command;"
ls /backup/postgresql/wal_archive/ | head -5

# 9. Monitoring exporter running
systemctl is-active postgres-exporter
curl -s http://localhost:9187/metrics | grep -c 'pg_' | head -1

# 10. Health check passes
/usr/local/bin/pg-healthcheck.sh
```

---

## Rollback

### Full Rollback — Remove Everything

```bash
# Stop all services
sudo systemctl stop postgres-exporter pgbouncer postgresql

# Remove PostgreSQL
sudo apt purge -y postgresql-16 postgresql-contrib-16 postgresql-client-16 pgbouncer
sudo apt autoremove -y

# Remove data
sudo rm -rf /var/lib/postgresql
sudo rm -rf /etc/postgresql
sudo rm -rf /backup/postgresql
sudo rm -rf /etc/pgbouncer
sudo rm -f /usr/local/bin/pg-*.sh
sudo rm -f /usr/local/bin/postgres_exporter
sudo rm -f /etc/systemd/system/postgres-exporter.service
sudo rm -f /etc/cron.d/pg-backup /etc/cron.d/pg-healthcheck
sudo rm -rf /etc/postgresql/ssl

# Remove firewall rules
sudo ufw delete allow 5432/tcp
sudo ufw delete allow 6432/tcp
sudo ufw delete allow 9187/tcp

# Remove users (on replicas too)
sudo userdel postgres 2>/dev/null || true

echo "Rollback complete"
```

### Partial Rollback — Restore Config Only

```bash
sudo cp /etc/postgresql/16/main/postgresql.conf.backup.* /etc/postgresql/16/main/postgresql.conf
sudo cp /etc/postgresql/16/main/pg_hba.conf.backup.* /etc/postgresql/16/main/pg_hba.conf
sudo systemctl restart postgresql
```

---

## Common Errors

### Error: "FATAL: password authentication failed for user"

**Cause**: Password mismatch or pg_hba.conf method incorrect.
**Solution**:
```bash
# Reset password
sudo -u postgres psql -c "ALTER USER app_user PASSWORD 'NewStrongP@ss2026!';"

# Verify pg_hba.conf method
grep app_user /etc/postgresql/16/main/pg_hba.conf
# Should show: scram-sha-256 (not md5 or trust)

sudo systemctl reload postgresql
```

### Error: "could not connect to server: Connection refused"

**Cause**: PostgreSQL not listening on the requested address.
**Solution**:
```bash
# Check listen_addresses
sudo -u postgres psql -c "SHOW listen_addresses;"
# Should be '*' or specific IP, not 'localhost'

# Check if listening
ss -tlnp | grep 5432

# Check firewall
sudo ufw status | grep 5432
```

### Error: "FATAL: no pg_hba.conf entry for host"

**Cause**: Client IP not allowed in pg_hba.conf.
**Solution**:
```bash
# Add client network to pg_hba.conf
echo "host all app_user 10.0.0.0/8 scram-sha-256" | sudo tee -a /etc/postgresql/16/main/pg_hba.conf
sudo systemctl reload postgresql
```

### Error: Replication lag increasing

**Cause**: Replica cannot keep up with WAL generation.
**Solution**:
```bash
# Check lag
sudo -u postgres psql -c "SELECT pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) FROM pg_stat_replication;"

# Check replica I/O
iostat -x 1 5

# Increase wal_keep_size on primary
sudo -u postgres psql -c "ALTER SYSTEM SET wal_keep_size = '2GB';"
sudo systemctl reload postgresql
```

### Error: "remaining connection slots are reserved for non-replication superuser connections"

**Cause**: max_connections reached.
**Solution**:
```bash
# Check current connections
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"

# Kill idle connections
sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle' AND query_start < now() - interval '1 hour';"

# Increase max_connections (requires restart)
sudo -u postgres psql -c "ALTER SYSTEM SET max_connections = 200;"
sudo systemctl restart postgresql
```

### Error: WAL archiving failing

**Cause**: Archive directory full or permission denied.
**Solution**:
```bash
# Check archive status
sudo -u postgres psql -c "SELECT archived_count, last_archived_wal, last_failed_wal, last_failed_time FROM pg_stat_archiver;"

# Check disk space
df /backup/postgresql/wal_archive/

# Fix permissions
sudo chown -R postgres:postgres /backup/postgresql/wal_archive/

# Restart archiver
sudo systemctl reload postgresql
```

---

## References

- [PostgreSQL 16 Documentation](https://www.postgresql.org/docs/16/)
- [PostgreSQL Streaming Replication](https://www.postgresql.org/docs/16/warm-standby.html)
- [pg_hba.conf Documentation](https://www.postgresql.org/docs/16/auth-pg-hba-conf.html)
- [PgBouncer Documentation](https://www.pgbouncer.org/config.html)
- [pg_dump Documentation](https://www.postgresql.org/docs/16/app-pgdump.html)
- [Prometheus postgres_exporter](https://github.com/prometheus-community/postgres_exporter)
- [PostgreSQL Security Best Practices](https://www.postgresql.org/docs/16/auth-pg-hba-conf.html)
- [Ubuntu PostgreSQL Wiki](https://wiki.ubuntu.com/PostgreSQL)
- [pgtune — PostgreSQL Configuration Tuner](https://pgtune.leopard.in.ua/)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server)

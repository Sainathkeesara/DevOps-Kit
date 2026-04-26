# Log Aggregation with Loki and Promtail

## Purpose

This project provides comprehensive guidance on setting up Loki for log aggregation and Promtail for log collection in a Linux environment. The stack enables centralized logging, querying, and visualization of logs across multiple servers and applications.

## When to Use

- Centralizing logs from multiple Linux servers
- Building a centralized logging infrastructure
- Implementing log-based alerting and monitoring
- Troubleshooting distributed applications
- Meeting compliance logging requirements
- Creating audit trails for security analysis

## Prerequisites

- Linux servers (Ubuntu 20.04+, RHEL 8+, Debian 11+)
- Root or sudo access on all servers
- At least 10GB free disk space for log storage
- Network connectivity between all servers
- Basic understanding of systemd and logging
- Grafana installed for visualization (optional but recommended)

## Steps

### Step 1: Plan the Architecture

Design your Loki deployment:

- Single instance: For small environments (up to 10 servers)
- HA cluster: For production environments requiring high availability
- Scalable: For large environments with many servers

Plan the storage requirements:
- Default retention: 30 days
- Average log rate: 100MB/hour per server
- Storage per server/month: ~70GB

### Step 2: Install Loki on the Central Server

```bash
# Download Loki
curl -s -L https://github.com/grafana/loki/releases/download/v3.2.0/loki_3.2.0_amd64.deb -o loki.deb
sudo dpkg -i loki.deb

# Or use binary installation
wget https://github.com/grafana/loki/releases/download/v3.2.0/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
sudo mv loki-linux-amd64 /usr/local/bin/loki
sudo mv promtail-linux-amd64 /usr/local/bin/promtail

# Create loki user
sudo useradd -r -s /bin/false loki

# Create directories
sudo mkdir -p /var/lib/loki /etc/loki /var/log/loki
sudo chown -R loki:loki /var/lib/loki /var/log/loki
```

### Step 3: Configure Loki

Create the Loki configuration file:

```bash
sudo tee /etc/loki/local-config.yaml > /dev/null << 'EOF'
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  path_prefix: /var/lib/loki
  storage:
    filesystem:
      chunks_directory: /var/lib/loki/chunks
      rules_directory: /var/lib/loki/rules
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  ingestion_rate_mb: 50
  ingestion_burst_size_mb: 100

schema_config:
  configs:
    - from: 2024-01-01
      store: boltdb-shipper
      object_store: filesystem
      schema: v12
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb:
    directory: /var/lib/loki/index
  filesystem:
    directory: /var/lib/loki/chunks

chunk_store_config:
  max_look_back_period: 720h

table_manager:
  retention_deletes_enabled: true
  retention_period: 720h
EOF

# Make Loki executable
sudo chmod +x /usr/local/bin/loki
```

### Step 4: Create Systemd Service for Loki

```bash
sudo tee /etc/systemd/system/loki.service > /dev/null << 'EOF'
[Unit]
Description=Loki Log Aggregator
After=network.target

[Service]
Type=simple
User=loki
ExecStart=/usr/local/bin/loki -config.file=/etc/loki/local-config.yaml
Restart=on-failure
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Reload and start Loki
sudo systemctl daemon-reload
sudo systemctl enable loki
sudo systemctl start loki
sudo systemctl status loki
```

### Step 5: Install Promtail on Client Servers

On each server that needs to send logs:

```bash
# Download Promtail
wget https://github.com/grafana/loki/releases/download/v3.2.0/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
sudo mv promtail-linux-amd64 /usr/local/bin/promtail

# Create promtail user
sudo useradd -r -s /bin/false promtail

# Create directories
sudo mkdir -p /var/lib/promtail /etc/promtail /var/log/promtail
sudo chown -R promtail:promtail /var/lib/promtail /var/log/promtail
```

### Step 6: Configure Promtail

Create the Promtail configuration:

```bash
sudo tee /etc/promtail/promtail-config.yaml > /dev/null << 'EOF'
server:
  http_listen_port: 9080
  grpc_listen_port: 9081

clients:
  - endpoint: http://loki-server:3100/loki/api/v1/push
    retry_interval: 5s
    batch_timeout: 10s
    external_labels:
      environment: production
      datacenter: dc1

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: system_logs
          host: $(hostname)
          __path__: /var/log/*.log

  - job_name: auth_logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: auth
          host: $(hostname)
          __path__: /var/log/auth.log

  - job_name: syslog
    syslog:
      listen_address: 0.0.0.0:514
      labels:
        job: syslog
        host: $(hostname)

  - job_name: journal
    journal:
      path: /var/log/journal
      labels:
        job: systemd
        host: $(hostname)

  - job_name: docker
    docker_targets:
      - containers
    labels:
      job: docker
      host: $(hostname)

  - job_name: application_logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: app-logs
          host: $(hostname)
        __path__: /var/log/application/*.log
EOF
```

### Step 7: Create Systemd Service for Promtail

```bash
sudo tee /etc/systemd/system/promtail.service > /dev/null << 'EOF'
[Unit]
Description=Promtail Log Shipper
After=network.target

[Service]
Type=simple
User=promtail
ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail/promtail-config.yaml
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload and start Promtail
sudo systemctl daemon-reload
sudo systemctl enable promtail
sudo systemctl start promtail
sudo systemctl status promtail
```

### Step 8: Configure Log Rotation

Prevent disk space issues with proper log rotation:

```bash
sudo tee /etc/logrotate.d/loki > /dev/null << 'EOF'
/var/log/loki/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 loki loki
    sharedscripts
    postrotate
        systemctl reload loki > /dev/null 2>&1 || true
    endscript
}
EOF

sudo tee /etc/logrotate.d/promtail > /dev/null << 'EOF'
/var/log/promtail/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 promtail promtail
}
EOF
```

### Step 9: Integrate with Grafana

Connect Loki to Grafana for visualization:

1. Open Grafana: http://grafana-server:3000
2. Go to Configuration → Data Sources
3. Add Loki with URL: http://loki-server:3100
4. Save and Test

### Step 10: Query Logs in Grafana

Example LogQL queries:

```logql
# All logs from a specific host
{host="web-server-01"}

# Error logs only
{job="app-logs"} |= "ERROR"

# Filter by message content
{job="system_logs"} |= "failed" |= "authentication"

# Performance metrics
rate({job="app-logs"}[5m])

# Count by level
count_over_time({job="app-logs"}[1h])
```

### Step 11: Set Up Alerts

Create alert rules in Grafana:

```yaml
# alerting-rules.yaml
groups:
  - name: loki_alerts
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate({job="app-logs"} |= "ERROR"[5m]))
          / sum(rate({job="app-logs"}[5m])) > 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is above 10%"

      - alert: MissingLogs
        expr: |
          absent({job="app-logs"}) > 10m
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "No logs received from app-logs"
```

## Verify

```bash
# Check Loki is running
curl -s http://localhost:3100/ready
# Expected: "ready"

# Check Loki service status
sudo systemctl status loki
# Expected: active (running)

# Check Promtail is running
curl -s http://localhost:9080/metrics
# Expected: Prometheus metrics

# Verify log ingestion
curl -s -G --data-urlencode 'query={job="system_logs"}' \
  http://localhost:3100/loki/api/v1/query | jq '.status'

# Check disk usage
df -h /var/lib/loki

# Verify log push endpoint
curl -s -X POST http://localhost:3100/loki/api/v1/push \
  -H "Content-Type: application/json" \
  --data-raw '{"streams":[{"stream":{"job":"test"},"values":[["$(date +%s)000000","test log"]]}]}'
```

## Rollback

```bash
# Stop Loki
sudo systemctl stop loki

# Restore from backup
sudo rm -rf /var/lib/loki/*
sudo tar -xzf loki-backup.tar.gz -C /

# Restart Loki
sudo systemctl start loki

# Alternative: use object storage
# Update config to use S3/GCS/Azure blob storage
```

## Common errors

| Error | Cause | Solution |
|-------|-------|----------|
| `connection refused` | Loki not running | Check: `systemctl status loki` |
| `endpoint not found` | Wrong URL in Promtail | Verify Loki URL in promtail-config.yaml |
| `permission denied` | File permission issues | Check: `chown -R promtail:promtail /var/lib/promtail` |
| `out of memory` | Not enough RAM | Increase memory in systemd service or scale horizontally |
| `disk full` | Log retention too long | Reduce retention period in loki-config.yaml |
| `too many outstanding requests` | Promtail buffer full | Adjust batch settings in promtail-config.yaml |
| `authentication failed` | Wrong endpoint | Ensure Loki URL is accessible from Promtail server |
| `400 Bad Request` | Invalid label format | Check labels don't contain special characters |

## References

- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Promtail Configuration](https://grafana.com/docs/loki/clients/promtail/)
- [LogQL Query Examples](https://grafana.com/docs/loki/latest/query/)
- [Grafana Loki Integration](https://grafana.com/docs/grafana/latest/datasources/loki/)
- [Loki Storage](https://grafana.com/docs/loki/latest/storage/)
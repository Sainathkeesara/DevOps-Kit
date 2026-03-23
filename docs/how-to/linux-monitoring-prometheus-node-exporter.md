# Linux System Monitoring Dashboard with Prometheus Node Exporter

## Purpose

This guide explains how to set up a comprehensive Linux system monitoring solution using Prometheus and node_exporter. The solution provides real-time visibility into CPU, memory, disk, network, and process metrics with persistent storage and alerting capabilities.

## When to Use

Use this monitoring solution when you need to:

- Monitor CPU, memory, disk I/O, and network metrics across multiple Linux servers
- Create a centralized monitoring dashboard accessible via web browser
- Set up alerts for resource exhaustion or service failures
- Track system performance trends over time for capacity planning
- Integrate with Grafana for visualization

## Prerequisites

### Required Tools
- **Prometheus** (v2.45+) — install via `apt-get install prometheus` or download from prometheus.io
- **node_exporter** (v1.6+) — install via the provided setup script
- **Grafana** (v10+) — for dashboard visualization (optional but recommended)
- **curl** — for health checks
- **systemd** — for service management

### Required Access
- Root or sudo privileges on target systems
- Network access between monitoring server and monitored systems (port 9100 for node_exporter, 9090 for Prometheus)
- Web browser access to Grafana dashboard (port 3000)

### Environment
- Ubuntu 20.04/22.04, RHEL 8/9, Debian 11/12
- At least 2 CPU cores and 2GB RAM for the monitoring server
- 10GB+ disk space for Prometheus time-series storage

## Steps

### Step 1: Install Node Exporter on All Target Systems

Run the setup script on each Linux server you want to monitor:

```bash
# Download the setup script
curl -O https://raw.githubusercontent.com/Sainathkeesara/DevOps-Kit/main/scripts/bash/linux_toolkit/monitoring/node-exporter-setup.sh
chmod +x node-exporter-setup.sh

# Preview installation (dry-run)
sudo ./node-exporter-setup.sh --dry-run

# Actually install
sudo ./node-exporter-setup.sh --version 1.8.2 --port 9100 --run
```

The script will:
- Create a dedicated `node_exporter` user
- Download and install node_exporter to `/opt/prometheus`
- Set up systemd service for auto-startup
- Configure firewall rules (if applicable)
- Start the service

### Step 2: Verify Node Exporter is Running

On each target system:

```bash
# Check service status
sudo systemctl status node_exporter

# Test metrics endpoint
curl http://localhost:9100/metrics | head -20

# Check listening port
sudo ss -tlnp | grep 9100
```

Expected output should include metrics like:
```
node_cpu_seconds_total{cpu="0",mode="idle"} 12345.67
node_memory_MemAvailable_bytes 8287607808
node_filesystem_avail_bytes{mountpoint="/",fstype="ext4"} 52345678912
```

### Step 3: Install and Configure Prometheus Server

On the monitoring server:

```bash
# Install Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xzf prometheus-2.45.0.linux-amd64.tar.gz
cd prometheus-2.45.0.linux-amd64

# Create prometheus user
sudo useradd --no-create-home --shell /usr/sbin/nologin prometheus

# Create directories
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

# Create configuration file
sudo cat > /etc/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

rule_files: []

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'linux-servers'
    static_configs:
      - targets: ['server1.example.com:9100', 'server2.example.com:9100']
        labels:
          group: 'production'
      - targets: ['server3.example.com:9100']
        labels:
          group: 'development'

  - job_name: 'node'
    scrape_interval: 30s
    static_configs:
      - targets: ['localhost:9100']
EOF
```

### Step 4: Set Up Prometheus Systemd Service

```bash
sudo cat > /etc/systemd/system/prometheus.service << 'EOF'
[Unit]
Description=Prometheus Monitoring System
Documentation=https://prometheus.io/docs/
After=network-online.target

[Service]
Type=simple
User=prometheus
ExecStart=/opt/prometheus/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus \
    --storage.tsdb.retention.time=30d \
    --web.console.templates=/opt/prometheus/consoles \
    --web.console.libraries=/opt/prometheus/console_libraries \
    --web.listen-address=:9090
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus
```

### Step 5: Verify Prometheus is Collecting Metrics

```bash
# Check Prometheus is running
curl http://localhost:9090/-/healthy

# Check targets in Prometheus UI
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health, lastError: .lastError}'
```

### Step 6: Install and Configure Grafana

```bash
# Install Grafana on Ubuntu/Debian
sudo apt-get install -y apt-transport-https software-properties-common
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/stable debian/stable" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install grafana

# Enable and start
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

### Step 7: Add Prometheus Data Source in Grafana

1. Open Grafana at http://localhost:3000 (default login: admin/admin)
2. Navigate to **Configuration** → **Data Sources**
3. Click **Add data source**
4. Select **Prometheus**
5. Configure:
   - URL: `http://localhost:9090`
   - Access: `Server (default)`
6. Click **Save & Test**

### Step 8: Import Node Exporter Dashboard

1. In Grafana, go to **Dashboards** → **Import**
2. Enter dashboard ID: **1860** (Node Exporter Full)
3. Select the Prometheus data source you just created
4. Click **Import**

This provides a comprehensive dashboard showing:
- CPU usage per core
- Memory utilization
- Disk I/O and space
- Network traffic
- System load
- Process information

### Step 9: Create Custom Alerts

Add alert rules to `/etc/prometheus/rules.yml`:

```yaml
groups:
  - name: linux_alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage has been above 80% for more than 5 minutes"

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 85%"

      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 15
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Disk space is below 15%"

      - alert: NodeDown
        expr: up{job="linux-servers"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Node {{ $labels.instance }} is down"
          description: "node_exporter is not responding"
```

Reload Prometheus configuration:
```bash
sudo systemctl reload prometheus
```

## Verify

### Verify Node Exporter
```bash
# Check metrics are exposed
curl http://localhost:9100/metrics | grep -E "^node_" | wc -l

# Should show 50+ metric lines
```

### Verify Prometheus Collection
```bash
# Check Prometheus UI at http://localhost:9090
# Navigate to Status → Targets — all targets should show "UP"

# Query metrics directly
curl 'http://localhost:9090/api/v1/query?query=up' | jq
```

### Verify Grafana Dashboard
```bash
# Check dashboard loads without errors
curl -s http://localhost:3000/api/dashboards/uid/node-exporter-full | jq '.dashboard.title'

# Check data source is working
curl -s http://localhost:3000/api/datasources/1/health | jq '.status'
```

## Rollback

### Remove Node Exporter from a Server
```bash
sudo systemctl stop node_exporter
sudo systemctl disable node_exporter
sudo rm /etc/systemd/system/node_exporter.service
sudo rm -rf /opt/prometheus
sudo userdel node_exporter 2>/dev/null || true
```

### Remove Prometheus Server
```bash
sudo systemctl stop prometheus
sudo systemctl disable prometheus
sudo rm -rf /etc/prometheus /var/lib/prometheus /opt/prometheus
sudo userdel prometheus 2>/dev/null || true
```

### Remove Grafana
```bash
sudo systemctl stop grafana-server
sudo apt-get remove --purge grafana
sudo rm -rf /etc/grafana /var/lib/grafana
```

## Common Errors

### Error: "Failed to start node_exporter: Unit node_exporter.service not found"
**Solution:** The service file wasn't created properly. Re-run the setup script:
```bash
sudo /opt/prometheus/node-exporter-setup.sh --run
```

### Error: "connect: connection refused" on port 9100
**Solution:** Check if node_exporter is running:
```bash
sudo systemctl status node_exporter
sudo ss -tlnp | grep 9100
```

### Error: Prometheus shows "context deadline exceeded" for targets
**Solution:** Network connectivity issue. Check firewall:
```bash
# On target server
sudo firewall-cmd --list-all
# Or check if port is open
telnet target-server 9100
```

### Error: Grafana shows "No data" in dashboard
**Solution:** Check data source configuration:
1. Verify Prometheus is accessible from Grafana server
2. Check Prometheus can scrape the target: `curl http://target:9100/metrics`
3. Check dashboard time range is correct (top-right corner)

### Warning: Prometheus storage space growing too fast
**Solution:** Adjust retention period in prometheus.yml:
```yaml
--storage.tsdb.retention.time=15d  # Reduce from 30d
```

## References

- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- [node_exporter GitHub](https://github.com/prometheus/node_exporter)
- [Grafana Dashboards](https://grafana.com/dashboards)
- [Prometheus Alerting Rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
- [node_exporter Textfile Collector](https://github.com/prometheus/node_exporter/blob/master/docs/textfile-collector.md)

## Additional Options

### Enable Authentication on node_exporter
Add basic auth to protect metrics endpoint:
```bash
# Create htpasswd file
sudo apt-get install apache2-utils
sudo htpasswd -bc /etc/node_exporter/htpasswd admin <password>

# Update systemd service with --web.config
```

### Add Custom Metrics with Textfile Collector
Create custom metrics that Prometheus can scrape:
```bash
# Create a script that outputs Prometheus metrics
cat > /usr/local/bin/custom-metrics.sh << 'EOF'
#!/bin/bash
echo '# HELP app_requests_total Total application requests'
echo '# TYPE app_requests_total counter'
app_requests_total 12345
EOF
chmod +x /usr/local/bin/custom-metrics.sh

# Add to cron
* * * * * /usr/local/bin/custom-metrics.sh > /var/lib/node_exporter/textfile_collector/app_metrics.prom
```

### Set Up High Availability
For production environments, run two Prometheus servers with identical configuration:
- Use a load balancer in front of both
- Alert on differences between the two scrapes

### Monitor Container Metrics
Add cAdvisor for container monitoring:
```bash
docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --publish=8080:8080 \
  gcr.io/cadvisor/cadvisor:latest
```

Then add to prometheus.yml:
```yaml
- job_name: 'cadvisor'
  static_configs:
    - targets: ['localhost:8080']
```

# Linux System Monitoring Dashboard with Prometheus Node Exporter

## Purpose

This guide explains how to set up a comprehensive Linux system monitoring solution using Prometheus and its node_exporter. The monitoring stack provides real-time visibility into CPU, memory, disk, network, and process metrics.

## When to use

- When you need to monitor Linux server metrics (CPU, memory, disk, network)
- When you want to integrate with Prometheus and Grafana for visualization
- When you need alerts on system resource thresholds
- When you want to track long-term trends and create capacity planning reports

## Prerequisites

- Linux server (RHEL/CentOS, Ubuntu, or Debian)
- Root or sudo access
- Firewall access (port 9100 for node_exporter, port 9090 for Prometheus)
- Optional: Grafana for visualization (recommended)

## Steps

### 1. Install Node Exporter

Run the setup script to install node_exporter:

```bash
# Dry-run first to preview
./scripts/bash/linux_toolkit/monitoring/node-exporter-setup.sh --dry-run

# Actual installation (requires root)
sudo ./scripts/bash/linux_toolkit/monitoring/node-exporter-setup.sh --version 1.8.2 --port 9100
```

### 2. Configure Prometheus

Add the following to your Prometheus `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          environment: 'production'
          role: 'linux-server'
```

Restart Prometheus after configuration changes.

### 3. Import Grafana Dashboard

1. Open Grafana at http://localhost:3000
2. Navigate to Dashboards → Import
3. Use Grafana Dashboard ID: **1860** (Node Exporter Full)
4. Select Prometheus data source

### 4. Set Up Alerts

Create alert rules in Prometheus:

```yaml
groups:
  - name: node_exporter_alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          
      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
```

### 5. Add Custom Metrics

Create custom metrics using the textfile collector:

```bash
# Create a script that outputs metrics
cat > /var/lib/node_exporter/textfile_collector/custom_metrics.prom << 'EOF'
# HELP custom_disk_usage_percent Current disk usage percentage
# TYPE custom_disk_usage_percent gauge
custom_disk_usage_percent{device="/"} $(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
EOF
```

## Verify

1. Check node_exporter is running:
   ```bash
   systemctl status node_exporter
   ```

2. Test metrics endpoint:
   ```bash
   curl http://localhost:9100/metrics | head -20
   ```

3. Check Prometheus target status:
   ```bash
   curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.job=="node")'
   ```

4. Verify Grafana dashboard shows metrics

## Rollback

To remove node_exporter:

```bash
# Stop service
sudo systemctl stop node_exporter
sudo systemctl disable node_exporter

# Remove files
sudo rm -f /etc/systemd/system/node_exporter.service
sudo rm -rf /opt/prometheus/node_exporter*

# Reload systemd
sudo systemctl daemon-reload

# Remove firewall rule (if added)
sudo firewall-cmd --permanent --remove-port=9100/tcp
sudo firewall-cmd --reload
```

## Common errors

### Connection refused on port 9100

- Check if service is running: `systemctl status node_exporter`
- Check logs: `journalctl -u node_exporter -f`
- Verify port is open: `ss -tlnp | grep 9100`

### Metrics not appearing in Prometheus

- Check Prometheus scrape config is valid: `promtool check config`
- Check target is up: `curl http://localhost:9090/api/v1/targets`
- Verify network connectivity: `telnet localhost 9100`

### Grafana dashboard shows "No data"

- Verify Prometheus data source is configured correctly
- Check time range in dashboard
- Verify metrics are being scraped: `curl http://localhost:9100/metrics | grep node_cpu`

### High resource usage from node_exporter

- Disable unnecessary collectors using `--collector.disable-defaults` and enable specific ones
- Adjust scrape interval in Prometheus config
- Use `--web.telemetry-path` to separate metrics endpoint

## References

- Node Exporter GitHub: https://github.com/prometheus/node_exporter
- Prometheus Documentation: https://prometheus.io/docs/prometheus/latest/getting_started/
- Grafana Node Exporter Dashboard: https://grafana.com/dashboards/1860
- Prometheus alerting rules: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
- Node Exporter textfile collector: https://github.com/prometheus/node_exporter#textfile-collector

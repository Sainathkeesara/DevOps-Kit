# Observability Snippets

## PromQL Queries

### CPU Usage
```promql
# Node CPU usage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Pod CPU usage
rate(container_cpu_usage_seconds_total{container!=""}[5m])
```

### Memory Usage
```promql
# Node memory
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# Pod memory
container_memory_working_set_bytes{container!=""}
```

### Request Rate
```promql
# HTTP requests per second
rate(http_requests_total[5m])

# By status code
rate(http_requests_total{status=~"2.."}[5m])
```

### Error Rate
```promql
# 5xx errors
rate(http_requests_total{status=~"5.."}[5m])

# Error percentage
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100
```

### Latency
```promql
# P50 latency
histogram_quantile(0.50, rate(http_request_duration_seconds_bucket[5m]))

# P95 latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# P99 latency
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
```

### Kubernetes
```promql
# Pod restarts
increase(kube_pod_container_status_restarts_total[1h])

# Deployment desired vs ready
kube_deployment_spec_replicas / kube_deployment_status_replicas_ready

# Persistent volume usage
kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes
```

## LogQL Queries

### Basic Filtering
```logql
{job="my-app"}
{namespace="production"}
{container_name="nginx"} |= "error"
{container_name="nginx"} |= "exception" or |= "error"
```

### Parsing
```logql
# JSON parsing
{job="app"} | json | level="error"

# Regex extraction
{job="app"} | regex "method=(?P<method>\w+)"
```

### Metrics from Logs
```logql
# Error rate per minute
count_over_time({job="app"} |= "error"[1m])

# Requests by method
sum by (method) (count_over_time({job="app"}[5m]))
```

## Grafana Dashboard JSON (Panel)

```json
{
  "title": "Service Overview",
  "type": "timeseries",
  "targets": [
    {
      "expr": "rate(http_requests_total[5m])",
      "legendFormat": "{{method}} {{status}}"
    }
  ],
  "gridPos": {"x": 0, "y": 0, "w": 12, "h": 8}
}
```

## Alert Rules

### High CPU
```yaml
groups:
- name: cpu-alerts
  rules:
  - alert: HighCPUUsage
    expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage on {{ $labels.instance }}"
```

### High Memory
```yaml
  - alert: HighMemoryUsage
    expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
    for: 5m
    labels:
      severity: warning
```

### Pod Restart Loop
```yaml
  - alert: PodRestartingTooMuch
    expr: increase(kube_pod_container_status_restarts_total[15m]) > 3
    for: 1m
    labels:
      severity: critical
```

## Docker Compose (Observability Stack)

```yaml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana

  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - ./loki-config.yml:/etc/loki/config.yaml
      - loki-data:/loki

  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"
      - "6831:6831/udp"

  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    ports:
      - "4317:4317"
      - "8888:8888"
      - "8889:8889"
    volumes:
      - ./otel-config.yaml:/etc/otelcol-contrib/config.yaml

volumes:
  prometheus-data:
  grafana-data:
  loki-data:
```

## Helm Commands

```bash
# Install kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Install Loki
helm install loki grafana/loki-stack \
  --namespace monitoring

# Install Jaeger
helm install jaeger jaegertracing/jaeger \
  --namespace monitoring
```

## Kubernetes ServiceMonitors

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: my-app
  endpoints:
  - port: metrics
    interval: 15s
```

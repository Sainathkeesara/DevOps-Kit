# Observability Toolkit

## Purpose

Scripts for managing and querying Prometheus, Grafana, Loki, Jaeger, and OpenTelemetry observability stack components.

## When to use

- Monitor observability stack health
- Query metrics from Prometheus
- Search logs in Loki
- Query traces in Jaeger
- Check OpenTelemetry collector status

## Prerequisites

- curl and jq installed
- Network access to observability endpoints
- Optional: GRAFANA_API_KEY for authenticated Grafana access

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| PROMETHEUS_HOST | localhost:9090 | Prometheus server |
| GRAFANA_HOST | localhost:3000 | Grafana server |
| LOKI_HOST | localhost:3100 | Loki server |
| JAEGER_HOST | localhost:16686 | Jaeger server |
| OTEL_HOST | localhost:8888 | OTel collector |
| OTEL_METRICS | localhost:8889 | OTel metrics endpoint |

## Scripts

### Prometheus

#### targets-status.sh

Check all Prometheus scrape targets and their health.

```bash
# Check all targets
./scripts/bash/observability_toolkit/prometheus/targets-status.sh

# With custom host
PROMETHEUS_HOST=prometheus:9090 ./scripts/bash/observability_toolkit/prometheus/targets-status.sh
```

#### check-alert.sh

Monitor specific Prometheus alerts.

```bash
# Check if alert is firing
./scripts/bash/observability_toolkit/prometheus/check-alert.sh 'HighCPUUsage'

# Check specific state
./scripts/bash/observability_toolkit/prometheus/check-alert.sh 'HighCPUUsage' firing
```

#### query-metrics.sh

Execute PromQL queries against Prometheus.

```bash
# Basic query
./scripts/bash/observability_toolkit/prometheus/query-metrics.sh 'up'

# Query with duration
./scripts/bash/observability_toolkit/prometheus/query-metrics.sh 'rate(http_requests_total[5m])' 1h

# Query container metrics
./scripts/bash/observability_toolkit/prometheus/query-metrics.sh 'container_cpu_usage_seconds_total{pod="my-app"}' 5m
```

### Loki

#### query-logs.sh

Query logs from Loki using LogQL.

```bash
# Basic query
./scripts/bash/observability_toolkit/loki/query-logs.sh '{job="my-app"}'

# Filter by error
./scripts/bash/observability_toolkit/loki/query-logs.sh '{job="my-app"} |= "error"' 50

# Filter by level
./scripts/bash/observability_toolkit/loki/query-logs.sh '| level="error"' 20
```

### Grafana

#### health-check.sh

Check Grafana health and list configured datasources.

```bash
./scripts/bash/observability_toolkit/grafana/health-check.sh

# With API key
GRAFANA_API_KEY=eyJrIjoi... ./scripts/bash/observability_toolkit/grafana/health-check.sh
```

### Jaeger

#### query-traces.sh

Query distributed traces from Jaeger.

```bash
# List available services
./scripts/bash/observability_toolkit/jaeger/query-traces.sh

# Query traces for a service
./scripts/bash/observability_toolkit/jaeger/query-traces.sh my-api-service 50
```

### OpenTelemetry

#### collector-health.sh

Check OpenTelemetry collector health and metrics.

```bash
# Check collector status
./scripts/bash/observability_toolkit/otel/collector-health.sh

# With custom endpoints
OTEL_HOST=otel-collector:8888 OTEL_METRICS=otel-collector:8889 ./scripts/bash/observability_toolkit/otel/collector-health.sh
```

### Stack Health

#### stack-health.sh

Check health of all observability stack components.

```bash
# Run all health checks
./scripts/bash/observability_toolkit/stack-health.sh

# With custom hosts
PROMETHEUS_HOST=prom:9090 GRAFANA_HOST=grafana:3000 LOKI_HOST=loki:3100 ./scripts/bash/observability_toolkit/stack-health.sh
```

## Verify

Run the stack health check to verify all components are accessible:

```bash
./scripts/bash/observability_toolkit/stack-health.sh
```

Expected output shows `[OK]` for each healthy service.

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| HTTP 000 | Service unreachable | Check service is running and network access |
| HTTP 401 | Authentication required | Set GRAFANA_API_KEY |
| jq: parse error | Invalid JSON response | Check service is healthy |
| No results | Query returned empty | Verify query syntax |

## References

- [Prometheus API](https://prometheus.io/docs/prometheus/latest/querying/api/)
- [Loki LogQL](https://grafana.com/docs/loki/latest/query/)
- [Jaeger Tracing API](https://www.jaegertracing.io/docs/1.48/apis/)
- [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)
- [Grafana HTTP API](https://grafana.com/docs/grafana/latest/http_api/)

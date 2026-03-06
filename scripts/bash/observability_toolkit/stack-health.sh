#!/bin/bash
set -euo pipefail

PROMETHEUS_HOST="${PROMETHEUS_HOST:-localhost:9090}"
GRAFANA_HOST="${GRAFANA_HOST:-localhost:3000}"
LOKI_HOST="${LOKI_HOST:-localhost:3100}"
JAEGER_HOST="${JAEGER_HOST:-localhost:16686}"
OTEL_HOST="${OTEL_HOST:-localhost:8888}"

DRY_RUN="${DRY_RUN:-false}"
FAILED=0

echo "========================================"
echo "  Observability Stack Health Check"
echo "========================================"
echo "Timestamp: $(date -Iseconds)"
echo ""

check_service() {
    local name=$1
    local url=$2
    local endpoint="${url}/health"
    
    if curl -sf --max-time 5 "$endpoint" >/dev/null 2>&1; then
        echo "[OK]   $name"
        return 0
    else
        echo "[FAIL] $name"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

check_service "Prometheus" "http://${PROMETHEUS_HOST}"
check_service "Grafana" "http://${GRAFANA_HOST}"
check_service "Loki" "http://${LOKI_HOST}"
check_service "Jaeger" "http://${JAEGER_HOST}"
check_service "OTel Collector" "http://${OTEL_HOST}"

echo ""
echo "========================================"
if [ $FAILED -eq 0 ]; then
    echo "All services healthy!"
    exit 0
else
    echo "$FAILED service(s) failed"
    exit 1
fi

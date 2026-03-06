#!/bin/bash
set -euo pipefail

OTEL_HOST="${OTEL_HOST:-localhost:8888}"
OTEL_METRICS="${OTEL_METRICS:-localhost:8889}"
DRY_RUN="${DRY_RUN:-false}"

echo "=== OpenTelemetry Collector Health ==="
echo "Collector: $OTEL_HOST"
echo "Metrics: $OTEL_METRICS"
echo ""

echo "=== Collector Health Endpoint ==="
RESPONSE=$(curl -s -w "\n%{http_code}" "http://${OTEL_HOST}/health" 2>/dev/null || echo -e "\n000")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "Status: HEALTHY"
else
    echo "Status: UNHEALTHY (HTTP $HTTP_CODE)"
fi

echo ""
echo "=== Receiver Status ==="
RESPONSE=$(curl -s "http://${OTEL_HOST}/api/v1/status" 2>/dev/null || echo '{"error": "failed"}')
echo "$RESPONSE" | jq -r '
    "Build Info: \(.buildInfo.version) (\(.buildInfo.gitHash[:7] // "N/A"))\n" +
    "Start Time: \(.startTimeUnixNano / 1000000000 | todate)"' 2>/dev/null || \
echo "$RESPONSE" | jq '.'

echo ""
echo "=== Collector Metrics ==="
curl -s "http://${OTEL_METRICS}/metrics" 2>/dev/null | head -n 20 || echo "Could not fetch metrics"

echo ""
echo "=== Key Metrics Summary ==="
curl -s "http://${OTEL_METRICS}/metrics" 2>/dev/null | grep -E "^otelcol_(receiver|exporter|processor)_(accepted|rejected|failed)" | head -n 10 || echo "No receiver/exporter metrics found"

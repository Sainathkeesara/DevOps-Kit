#!/bin/bash
set -euo pipefail

JAEGER_HOST="${JAEGER_HOST:-localhost:16686}"
SERVICE="${1:-}"
LIMIT="${2:-20}"
DRY_RUN="${DRY_RUN:-false}"

if [ -z "$SERVICE" ]; then
    echo "Usage: $0 <service-name> [limit]"
    echo "Example: $0 my-api-service 50"
    echo ""
    echo "To list available services, run without arguments"
fi

echo "=== Jaeger Trace Query ==="
echo "Host: $JAEGER_HOST"
echo ""

if [ -z "$SERVICE" ]; then
    echo "=== Available Services ==="
    RESPONSE=$(curl -s "http://${JAEGER_HOST}/api/services" 2>/dev/null || echo '{"error": "failed"}')
    echo "$RESPONSE" | jq -r '.data[] // .error' 2>/dev/null || echo "$RESPONSE"
    exit 0
fi

echo "Service: $SERVICE"
echo "Limit: $LIMIT"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "Content-Type: application/json" \
    "http://${JAEGER_HOST}/api/traces?service=${SERVICE}&limit=${LIMIT}" 2>/dev/null || echo -e "\n000")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    COUNT=$(echo "$BODY" | jq -r '.data | length')
    echo "Traces found: $COUNT"
    echo ""
    echo "$BODY" | jq -r '.data[] | 
        "TraceID: \(.traceID)\n" +
        "Duration: \(.duration)ms\n" +
        "Services: \((.processes | to_entries | map(.value.serviceName)) | join(", "))\n" +
        "Spans: \(.spans | length)\n"' 2>/dev/null || \
    echo "$BODY" | jq '.data'
else
    echo "ERROR: Failed to query Jaeger (HTTP $HTTP_CODE)"
    exit 1
fi

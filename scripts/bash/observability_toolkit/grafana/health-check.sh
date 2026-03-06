#!/bin/bash
set -euo pipefail

GRAFANA_HOST="${GRAFANA_HOST:-localhost:3000}"
GRAFANA_API_KEY="${GRAFANA_API_KEY:-}"
DRY_RUN="${DRY_RUN:-false}"

echo "=== Grafana Health Check ==="
echo "Host: $GRAFANA_HOST"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "Content-Type: application/json" \
    ${GRAFANA_API_KEY:+-H "Authorization: Bearer $GRAFANA_API_KEY"} \
    "http://${GRAFANA_HOST}/api/health" 2>/dev/null || echo -e "\n000")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "Grafana Status: OK"
    echo "$BODY" | jq '.'
else
    echo "ERROR: Grafana health check failed (HTTP $HTTP_CODE)"
    echo "$BODY"
    exit 1
fi

echo ""
echo "=== Datasources ==="
DS_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "Content-Type: application/json" \
    ${GRAFANA_API_KEY:+-H "Authorization: Bearer $GRAFANA_API_KEY"} \
    "http://${GRAFANA_HOST}/api/datasources" 2>/dev/null || echo -e "\n000")

DS_HTTP=$(echo "$DS_RESPONSE" | tail -n1)
DS_BODY=$(echo "$DS_RESPONSE" | head -n-1)

if [ "$DS_HTTP" = "200" ]; then
    echo "$DS_BODY" | jq -r '.[] | "\(.type): \(.name) - \(.url)"'
else
    echo "WARNING: Could not fetch datasources (HTTP $DS_HTTP)"
fi

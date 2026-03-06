#!/bin/bash
set -euo pipefail

PROMETHEUS_HOST="${PROMETHEUS_HOST:-localhost:9090}"
DRY_RUN="${DRY_RUN:-false}"

echo "=== Prometheus Targets Status ==="
echo "Prometheus: $PROMETHEUS_HOST"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" "http://${PROMETHEUS_HOST}/api/v1/targets" 2>/dev/null || echo -e "\n000")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "$BODY" | jq -r '
        .data.activeTargets[] |
        "Job: \(.labels.job // "N/A") | Endpoint: \(.scrapeUrl) | State: \(.health)"' 2>/dev/null || \
    echo "$BODY"
    
    echo ""
    echo "=== Summary ==="
    UP=$(echo "$BODY" | jq -r '.data.activeTargets[] | select(.health=="up") | .health' 2>/dev/null | wc -l)
    DOWN=$(echo "$BODY" | jq -r '.data.activeTargets[] | select(.health!="up") | .health' 2>/dev/null | wc -l)
    echo "Up: $UP | Down: $DOWN"
    
    if [ "$DOWN" -gt 0 ]; then
        echo ""
        echo "=== Down Targets ==="
        echo "$BODY" | jq -r '.data.activeTargets[] | select(.health!="up") | "Job: \(.labels.job) | Endpoint: \(.scrapeUrl) | Health: \(.health) | Error: \(.lastError // "N/A")"'
        exit 1
    fi
else
    echo "ERROR: Failed to connect to Prometheus (HTTP $HTTP_CODE)"
    exit 1
fi

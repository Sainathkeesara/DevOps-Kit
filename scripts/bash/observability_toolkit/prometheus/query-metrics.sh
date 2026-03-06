#!/bin/bash
set -euo pipefail

PROMETHEUS_HOST="${PROMETHEUS_HOST:-localhost:9090}"
QUERY="${1:-up}"
DRY_RUN="${DRY_RUN:-false}"

if [ -z "$QUERY" ]; then
    echo "Usage: $0 '<promql-query>' [duration]"
    echo "Example: $0 'rate(http_requests_total[5m])' 1h"
    echo "Example: $0 'container_cpu_usage_seconds_total{pod=\"my-app\"}' 5m"
    exit 1
fi

DURATION="${2:-5m}"
DRY_RUN="$DRY_RUN" QUERY="$QUERY" DURATION="$DURATION"

echo "=== Prometheus Query ==="
echo "Query: $QUERY"
echo "Duration: $DURATION"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" \
    --data-urlencode "query=$QUERY" \
    --data-urlencode "time=$(date +%s)" \
    "http://${PROMETHEUS_HOST}/api/v1/query" 2>/dev/null || echo -e "\n000")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    STATUS=$(echo "$BODY" | jq -r '.status')
    if [ "$STATUS" = "success" ]; then
        RESULT_COUNT=$(echo "$BODY" | jq -r '.data.result | length')
        echo "Results: $RESULT_COUNT"
        echo ""
        echo "$BODY" | jq -r '.data.result[] | 
            "Metric: \(.metric | to_entries | map("\(.key)=\(.value)") | join(", "))\n" +
            "Value: \(.value[1])"' 2>/dev/null || \
        echo "$BODY" | jq '.data.result'
    else
        echo "ERROR: Query failed - $(echo "$BODY" | jq -r '.error')"
        exit 1
    fi
else
    echo "ERROR: Failed to connect to Prometheus (HTTP $HTTP_CODE)"
    exit 1
fi

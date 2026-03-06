#!/bin/bash
set -euo pipefail

PROMETHEUS_HOST="${PROMETHEUS_HOST:-localhost:9090}"
ALERT_NAME="${1:-}"
DRY_RUN="${DRY_RUN:-false}"

if [ -z "$ALERT_NAME" ]; then
    echo "Usage: $0 <alert-name> [state]"
    echo "Example: $0 'HighCPUUsage' firing"
    echo ""
    echo "States: firing, pending, inactive"
    exit 1
fi

STATE="${2:-firing}"

echo "=== Checking Alert: $ALERT_NAME (State: $STATE) ==="

RESPONSE=$(curl -s -w "\n%{http_code}" "http://${PROMETHEUS_HOST}/api/v1/alerts" 2>/dev/null || echo -e "\n000")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    RESULT=$(echo "$BODY" | jq -r --arg NAME "$ALERT_NAME" --arg STATE "$STATE" \
        '.data.alerts[] | select(.name==$NAME and .state==$STATE)')
    
    if [ -n "$RESULT" ] && [ "$RESULT" != "null" ]; then
        echo "Alert '$ALERT_NAME' is $STATE"
        echo "$RESULT" | jq -r '
            "Severity: \(.labels.severity // "N/A")\n" +
            "Summary: \(.annotations.summary // "N/A")\n" +
            "Description: \(.annotations.description // "N/A")\n" +
            "Active since: \(.activeAt // "N/A")"'
        exit 0
    else
        echo "Alert '$ALERT_NAME' is NOT $STATE"
        CURRENT_STATE=$(echo "$BODY" | jq -r --arg NAME "$ALERT_NAME" \
            '.data.alerts[] | select(.name==$NAME) | .state' 2>/dev/null || echo "not found")
        echo "Current state: $CURRENT_STATE"
        exit 1
    fi
else
    echo "ERROR: Failed to connect to Prometheus (HTTP $HTTP_CODE)"
    exit 1
fi

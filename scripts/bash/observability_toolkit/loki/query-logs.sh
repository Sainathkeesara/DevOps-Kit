#!/bin/bash
set -euo pipefail

LOKI_HOST="${LOKI_HOST:-localhost:3100}"
QUERY="${1:-}"
LIMIT="${2:-100}"
DRY_RUN="${DRY_RUN:-false}"

if [ -z "$QUERY" ]; then
    echo "Usage: $0 '<logql-query>' [limit]"
    echo "Example: $0 '{job=\"my-app\"}' 50"
    echo "Example: $0 'rate(logger[5m])' 20"
    echo ""
    echo "Common patterns:"
    echo "  {job=\"<name>\"}           - Logs from specific job"
    echo "  {namespace=\"<ns>\"}      - Logs from namespace"
    echo "  |= \"error\"              - Filter by text"
    echo "  | level=\"error\"         - Filter by label"
    exit 1
fi

echo "=== Loki Log Query ==="
echo "Query: $QUERY"
echo "Limit: $LIMIT"
echo ""

ENCODED_QUERY=$(echo "$QUERY" | jq -sRr @uri)

RESPONSE=$(curl -s -w "\n%{http_code}" \
    "http://${LOKI_HOST}/loki/api/v1/query_range?query=${ENCODED_QUERY}&limit=${LIMIT}&direction=backward" 2>/dev/null || echo -e "\n000")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    STATUS=$(echo "$BODY" | jq -r '.status')
    if [ "$STATUS" = "success" ]; then
        RESULTS=$(echo "$BODY" | jq -r '.data.result | length')
        echo "Results: $RESULTS"
        echo ""
        echo "$BODY" | jq -r '.data.result[].values[] | 
            "[\(. [0] | todate)] \(. [1])"' 2>/dev/null | head -n "$LIMIT" || \
        echo "$BODY" | jq '.data.result'
    else
        echo "ERROR: Query failed"
        exit 1
    fi
else
    echo "ERROR: Failed to connect to Loki (HTTP $HTTP_CODE)"
    exit 1
fi

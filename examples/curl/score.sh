#!/usr/bin/env bash
# Score estimation example with Kai / Jev
# Usage:
#   ./score.sh                           # uses default model "kai"
#   KAI_MODEL="typesafe/jev-1.13" ./score.sh # uses Jev

set -euo pipefail

MODEL="${KAI_MODEL:-kai}"
API_KEY="${HANZO_API_KEY:-${1:-}}"

if [ -z "$API_KEY" ]; then
  echo "Error: HANZO_API_KEY is required (set env var or pass as first argument)" >&2
  exit 1
fi

curl -sS --fail-with-body -X POST https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"state\": \"Database connection pool exhausted. 95% of API requests returning 500 status code.\",
    \"questions\": {
      \"severity\": {
        \"type\": \"score\",
        \"instructions\": \"Assess incident severity\",
        \"criteria\": [
          \"low: non-critical glitch\",
          \"medium: minor latency increase\",
          \"high: subset of customers impacted\",
          \"critical: complete production service outage\"
        ]
      }
    }
  }" | jq .

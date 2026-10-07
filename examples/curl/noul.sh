#!/usr/bin/env bash
# Noul (boolean proposition) example with Kai / Jev
# Usage:
#   ./noul.sh                           # uses default model "kai"
#   KAI_MODEL="typesafe/jev-1.13" ./noul.sh # uses Jev probabilistic reasoning

MODEL="${KAI_MODEL:-kai}"
API_KEY="${HANZO_API_KEY:-$1}"

if [ -z "$API_KEY" ]; then
  echo "Error: HANZO_API_KEY is required (set env var or pass as first argument)" >&2
  exit 1
fi

curl -s -X POST https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"state\": \"Customer has spent $12,000 this year, but submitted 4 negative tickets this week saying: None of our integrations work.\",
    \"questions\": {
      \"is_churn_risk\": {
        \"type\": \"noul\",
        \"instructions\": \"Is this high-value account at immediate risk of cancelling?\"
      }
    }
  }" | jq .

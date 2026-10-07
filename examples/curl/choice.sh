#!/usr/bin/env bash
# Choice classification example with Kai / Jev
# Usage:
#   ./choice.sh                           # uses default model "kai"
#   KAI_MODEL="typesafe/jev-1.13" ./choice.sh # uses Jev probabilistic reasoning

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
    \"state\": \"The user submitted a support ticket asking: How do I change the billing credit card on our organization account?\",
    \"questions\": {
      \"department\": {
        \"type\": \"choice\",
        \"instructions\": \"Route this ticket to the right department\",
        \"criteria\": {
          \"billing\": \"credit card, invoices, receipts, payment methods\",
          \"technical\": \"API errors, bugs, downtime, latency\",
          \"sales\": \"upgrades, enterprise quotes, annual contracts\"
        }
      }
    }
  }" | jq .

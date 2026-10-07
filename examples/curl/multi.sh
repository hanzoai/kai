#!/usr/bin/env bash
# Multi-question compound decision example with Kai / Jev
# Usage:
#   ./multi.sh                           # uses default model "kai"
#   KAI_MODEL="typesafe/jev-1.13" ./multi.sh # uses Jev probabilistic reasoning

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
    \"state\": {
      \"command\": \"rm -rf /var/log/*\",
      \"user_role\": \"developer\",
      \"environment\": \"production\"
    },
    \"questions\": {
      \"risk_level\": {
        \"type\": \"score\",
        \"instructions\": \"Assess command destruction risk\",
        \"criteria\": [\"safe: read only\", \"guarded: reversible write\", \"destructive: irreversible deletion\"]
      },
      \"requires_mfa\": {
        \"type\": \"noul\",
        \"instructions\": \"Should multi-factor authentication be enforced before execution?\"
      },
      \"action\": {
        \"type\": \"choice\",
        \"instructions\": \"Select gate policy verdict\",
        \"criteria\": {
          \"allow\": \"safe to run automatically\",
          \"ask\": \"require manager confirmation\",
          \"deny\": \"block command completely\"
        }
      }
    }
  }" | jq .

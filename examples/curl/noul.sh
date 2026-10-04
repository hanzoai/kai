#!/usr/bin/env bash
curl -s -X POST https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "kai",
    "state": "Customer has spent $12,000 this year, but submitted 4 negative tickets this week saying: None of our integrations work.",
    "questions": {
      "is_churn_risk": {
        "type": "noul",
        "instructions": "Is this high-value account at immediate risk of cancelling?"
      }
    }
  }' | jq .

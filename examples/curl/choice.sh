#!/usr/bin/env bash
curl -s -X POST https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "kai",
    "state": "The user submitted a support ticket asking: How do I change the billing credit card on our organization account?",
    "questions": {
      "department": {
        "type": "choice",
        "instructions": "Route this ticket to the right department",
        "criteria": {
          "billing": "credit card, invoices, receipts, payment methods",
          "technical": "API errors, bugs, downtime, latency",
          "sales": "upgrades, enterprise quotes, annual contracts"
        }
      }
    }
  }' | jq .

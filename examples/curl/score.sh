#!/usr/bin/env bash
curl -s -X POST https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "kai",
    "state": "Database connection pool exhausted. 95% of API requests returning 500 status code.",
    "questions": {
      "severity": {
        "type": "score",
        "instructions": "Assess incident severity",
        "criteria": [
          "low: non-critical glitch",
          "medium: minor latency increase",
          "high: subset of customers impacted",
          "critical: complete production service outage"
        ]
      }
    }
  }' | jq .

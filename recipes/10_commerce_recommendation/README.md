# Commerce: Next-Best Subscription Plan Recommendation

Analyze a developer's token usage velocity and model preferences to recommend the ideal plan upgrade.

## Request Payload (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "current_plan": "Free",
    "monthly_tokens": 1400000,
    "frequent_models": [
      "zen-coder",
      "zen-vl"
    ],
    "rate_limit_hits_last_7d": 18
  },
  "questions": {
    "recommended_plan": {
      "type": "choice",
      "instructions": "Which plan provides best value and capacity?",
      "criteria": {
        "developer_pro": "$20/mo with 500 RPM and priority inference",
        "dedicated_team": "$199/mo with warm GPU instances and team seats",
        "custom_enterprise": "negotiated annual commitment with SLA"
      }
    }
  }
}
```

## Run with cURL
```bash
curl -X POST https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @request.json
```

## Run with Python
```bash
python3 run.py
```

## Run with TypeScript
```bash
npx tsx run.ts
```

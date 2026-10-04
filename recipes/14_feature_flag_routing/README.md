# Product: Dynamic Feature Experimentation Routing

Evaluate whether an active user should be enrolled in a bleeding-edge beta feature flag based on usage profile.

## Request Payload (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "user_account_age_days": 180,
    "monthly_active_days": 26,
    "is_developer_tier": true,
    "feedback_score": 4.9
  },
  "questions": {
    "enroll_in_beta": {
      "type": "noul",
      "instructions": "Is this user a high-reliability candidate for experimental beta features?"
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

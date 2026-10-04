# Sales: Inbound Lead BANT Qualification

Score incoming inbound leads on Budget, Authority, Need, and Timeline (BANT) to prioritize enterprise SDR outreach.

## Request Payload (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "work_email": "cto@fintechscale.com",
    "company_size": "250-500",
    "use_case": "Migrating 200 developers from Copilot to self-hosted Zen Coder models on private VPC.",
    "budget": "$100k-$250k annual allocated",
    "timeline": "Deploying within 30 days"
  },
  "questions": {
    "lead_tier": {
      "type": "choice",
      "instructions": "Categorize enterprise lead quality",
      "criteria": {
        "tier_1_strategic": "enterprise with immediate budget, clear technical fit, and urgent timeline",
        "tier_2_growth": "mid-market with valid use case and evaluation budget",
        "tier_3_nurture": "early stage or student with unclear timeline"
      }
    },
    "qualification_score": {
      "type": "score",
      "instructions": "Overall lead score",
      "criteria": [
        "0: disqualified",
        "1: low fit",
        "2: moderate fit",
        "3: high fit",
        "4: ideal customer profile (ICP)"
      ]
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

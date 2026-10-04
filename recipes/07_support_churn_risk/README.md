# Customer Support: Real-Time Churn Detection

Identify churn signals in real time during customer support interactions to immediately trigger retention interventions.

## Request Payload (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "customer_mrr": 450,
    "tenure_months": 14,
    "message": "We have been dealing with API 502 errors all week. We cannot afford this downtime and are looking into moving our stack to AWS Bedrock if this isn't resolved today."
  },
  "questions": {
    "churn_propensity": {
      "type": "noul",
      "instructions": "Is this customer actively planning to cancel or switch providers?"
    },
    "executive_escalation": {
      "type": "choice",
      "instructions": "Should an engineering leader or VP jump on this ticket?",
      "criteria": {
        "standard_support": "standard Tier-2 support resolution",
        "executive_outreach": "immediate personal email/call from Founder or Head of Customer Success"
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

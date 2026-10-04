# Customer Support: Multi-Class Ticket Triage

Classify incoming tickets into the correct team queue with calibrated confidence scores, routing directly when confidence exceeds 90%.

## Request Payload (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "subject": "Charged twice for October subscription",
    "body": "I saw two pending charges of $99 on my Visa statement this morning. Please refund the duplicate transaction immediately.",
    "account_tier": "Pro"
  },
  "questions": {
    "department": {
      "type": "choice",
      "instructions": "Which department handles this ticket?",
      "criteria": {
        "billing": "charges, invoices, refunds, credit card updates",
        "technical": "bug reports, integration errors, API downtime",
        "security": "unauthorized account access, audit logs",
        "sales": "enterprise discounts, contract upgrades"
      }
    },
    "priority": {
      "type": "score",
      "instructions": "Rate ticket priority",
      "criteria": [
        "low",
        "normal",
        "high",
        "urgent"
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

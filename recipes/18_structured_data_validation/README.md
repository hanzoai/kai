# Data Integrity: LLM Output Compliance Validator

Deterministically validate that generative LLM output complies with business constraints and contains zero hallucinations.

## Request Payload (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "extracted_invoice": {
      "vendor": "Acme Cloud Services",
      "subtotal": 100.0,
      "tax": 10.0,
      "total": 125.0
    }
  },
  "questions": {
    "is_arithmetically_valid": {
      "type": "noul",
      "instructions": "Does the subtotal + tax exactly equal the stated total?"
    },
    "confidence_rating": {
      "type": "score",
      "instructions": "Score data extraction confidence",
      "criteria": [
        "unreliable / contradictory",
        "partial confidence",
        "fully verified"
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

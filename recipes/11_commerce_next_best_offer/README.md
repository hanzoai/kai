# Commerce: Retention Discount & Promotion Offer

When an active user considers downgrading or hits payment abandonment, select the right promotional incentive.

## Request Payload (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "user_id": "usr_99182",
    "event": "checkout_abandoned",
    "target_plan": "Developer Pro ($20/mo)",
    "total_lifetime_tokens": 352000
  },
  "questions": {
    "offer_type": {
      "type": "choice",
      "instructions": "Select incentive to convert abandoned checkout",
      "criteria": {
        "percent_discount": "50% off first 3 months ($10/mo)",
        "credit_grant": "$25 complimentary token credits",
        "personal_onboarding": "direct 15-minute onboarding call with engineering founder"
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

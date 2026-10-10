# Commerce: Checkout Recovery Offer

Pick the incentive to offer a user who abandoned checkout, given the reason they left.

## Request (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "user_id": "usr_99182",
    "event": "checkout_abandoned",
    "target_plan": "Developer Pro ($20/mo)",
    "total_lifetime_tokens": 352000,
    "exit_survey": "I could not get it connected to my repository"
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

## Checked answers (`expect.json`)

- `offer_type` (choice): `personal_onboarding`

## Run

From the repository root, after `pip install -r requirements.txt` and `npm install`:

```bash
curl -sS --fail-with-body https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @recipes/11_commerce_next_best_offer/request.json

python3 recipes/11_commerce_next_best_offer/run.py
npx tsx recipes/11_commerce_next_best_offer/run.ts
```

`run.py` and `run.ts` print every answer and exit 1 when a checked answer is wrong.

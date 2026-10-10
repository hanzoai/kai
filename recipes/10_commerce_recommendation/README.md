# Commerce: Plan Recommendation

Pick the plan to offer a developer from their usage and rate-limit history.

## Request (`request.json`)

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

## Checked answers (`expect.json`)

- `recommended_plan` (choice): `developer_pro`

## Run

From the repository root, after `pip install -r requirements.txt` and `npm install`:

```bash
curl -sS --fail-with-body https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @recipes/10_commerce_recommendation/request.json

python3 recipes/10_commerce_recommendation/run.py
npx tsx recipes/10_commerce_recommendation/run.ts
```

`run.py` and `run.ts` print every answer and exit 1 when a checked answer is wrong.

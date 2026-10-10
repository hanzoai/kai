# Product: Beta Enrollment

Ask Kai whether a user fits an experimental beta from their usage profile.

## Request (`request.json`)

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

## Checked answers (`expect.json`)

- `enroll_in_beta` (noul): P(true) above 0.5

## Run

From the repository root, after `pip install -r requirements.txt` and `npm install`:

```bash
curl -sS --fail-with-body https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @recipes/14_feature_flag_routing/request.json

python3 recipes/14_feature_flag_routing/run.py
npx tsx recipes/14_feature_flag_routing/run.ts
```

`run.py` and `run.ts` print every answer and exit 1 when a checked answer is wrong.

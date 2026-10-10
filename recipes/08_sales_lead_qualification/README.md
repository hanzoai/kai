# Sales: Inbound Lead Qualification

Sort an inbound lead into a tier and give it an overall fit score.

## Request (`request.json`)

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

## Checked answers (`expect.json`)

- `lead_tier` (choice): `tier_1_strategic`
- `qualification_score` (score): most probable level 3 `3: high fit` or level 4 `4: ideal customer profile (ICP)`

## Run

From the repository root, after `pip install -r requirements.txt` and `npm install`:

```bash
curl -sS --fail-with-body https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @recipes/08_sales_lead_qualification/request.json

python3 recipes/08_sales_lead_qualification/run.py
npx tsx recipes/08_sales_lead_qualification/run.ts
```

`run.py` and `run.ts` print every answer and exit 1 when a checked answer is wrong.

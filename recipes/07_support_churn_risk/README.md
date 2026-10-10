# Customer Support: Churn Risk

Ask Kai whether a customer's support message says they may leave, and whether it needs a leader's attention.

## Request (`request.json`)

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

## Checked answers (`expect.json`)

- `churn_propensity` (noul): P(true) above 0.5
- `executive_escalation` (choice): not checked, no obvious answer on this input

## Run

From the repository root, after `pip install -r requirements.txt` and `npm install`:

```bash
curl -sS --fail-with-body https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @recipes/07_support_churn_risk/request.json

python3 recipes/07_support_churn_risk/run.py
npx tsx recipes/07_support_churn_risk/run.ts
```

`run.py` and `run.ts` print every answer and exit 1 when a checked answer is wrong.

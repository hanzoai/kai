# Customer Support: Ticket Triage

Route a support ticket to a team and rate its priority.

## Request (`request.json`)

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

## Checked answers (`expect.json`)

- `department` (choice): `billing`
- `priority` (score): most probable level 2 `high` or level 3 `urgent`

## Run

From the repository root, after `pip install -r requirements.txt` and `npm install`:

```bash
curl -sS --fail-with-body https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @recipes/06_support_triage/request.json

python3 recipes/06_support_triage/run.py
npx tsx recipes/06_support_triage/run.ts
```

`run.py` and `run.ts` print every answer and exit 1 when a checked answer is wrong.

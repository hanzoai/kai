# Sales: Next Action

Pick the next sales step for a prospect from their interaction history.

## Request (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "prospect": "VP Engineering at MedTech Co",
    "history": [
      "downloaded whitepaper on HIPAA compliance with private models",
      "attended webinar on agent security",
      "created free developer account and tested 50 API queries",
      "asked in the webinar Q&A for a live walkthrough with their security team"
    ]
  },
  "questions": {
    "next_action": {
      "type": "choice",
      "instructions": "What is the optimal next engagement step?",
      "criteria": {
        "book_demo": "direct calendar link for technical demo with Solutions Architect",
        "send_case_study": "email healthcare case study and security audit results",
        "invite_slack": "invite to private developer Slack channel"
      }
    }
  }
}
```

## Checked answers (`expect.json`)

- `next_action` (choice): `book_demo`

## Run

From the repository root, after `pip install -r requirements.txt` and `npm install`:

```bash
curl -sS --fail-with-body https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @recipes/09_sales_next_action/request.json

python3 recipes/09_sales_next_action/run.py
npx tsx recipes/09_sales_next_action/run.ts
```

`run.py` and `run.ts` print every answer and exit 1 when a checked answer is wrong.

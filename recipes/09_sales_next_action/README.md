# Sales: Next Best Action Recommendation

Determine the highest-converting sales touchpoint based on prospect interaction history.

## Request Payload (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "prospect": "VP Engineering at MedTech Co",
    "history": [
      "downloaded whitepaper on HIPAA compliance with private models",
      "attended webinar on agent security",
      "created free developer account and tested 50 API queries"
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

# Agent Completion Check

Before an agent stops, ask Kai whether the work it reports covers everything the user asked for.

## Request (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "user_request": "Implement password reset flow with email token validation and 15-minute expiration test.",
    "completed_work": [
      "created /api/v1/auth/reset-password endpoint",
      "token generation logic using crypto.randomBytes",
      "written test for valid token verification",
      "written test for expired token rejection"
    ],
    "test_run_result": "12 tests passed, 0 failures"
  },
  "questions": {
    "is_complete": {
      "type": "noul",
      "instructions": "Are all requirements in the user request satisfied?"
    },
    "quality_score": {
      "type": "score",
      "instructions": "Grade completeness and test coverage",
      "criteria": [
        "incomplete",
        "partially implemented",
        "complete with full tests"
      ]
    }
  }
}
```

## Checked answers (`expect.json`)

- `is_complete` (noul): P(true) above 0.5
- `quality_score` (score): most probable level 2 `complete with full tests`

## Run

From the repository root, after `pip install -r requirements.txt` and `npm install`:

```bash
curl -sS --fail-with-body https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @recipes/05_agent_completion_check/request.json

python3 recipes/05_agent_completion_check/run.py
npx tsx recipes/05_agent_completion_check/run.ts
```

`run.py` and `run.ts` print every answer and exit 1 when a checked answer is wrong.

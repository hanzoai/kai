# Agent Completion: Definition of Done Verification

Before an agent calls stop, verify that all requested deliverables, edge cases, and test assertions are satisfied.

## Request Payload (`request.json`)

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

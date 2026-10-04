# Agent Progress & Loop Detection

Evaluate whether an agent is making forward progress toward goal convergence or stuck spinning its wheels in an unproductive failure loop.

## Request Payload (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "goal": "Make all vitest tests pass in src/lib/auth",
    "history": [
      "turn 1: ran tests -> 2 failed",
      "turn 2: edited auth.ts -> ran tests -> 2 failed (same error)",
      "turn 3: edited auth.ts -> ran tests -> 2 failed (same error)",
      "turn 4: edited auth.ts -> ran tests -> 2 failed (same error)"
    ]
  },
  "questions": {
    "is_stuck": {
      "type": "noul",
      "instructions": "Is the agent caught in an unproductive loop?"
    },
    "next_strategy": {
      "type": "choice",
      "instructions": "What recovery action should the agent runtime take?",
      "criteria": {
        "continue": "allow another turn with existing strategy",
        "rollback": "revert last changes to git HEAD and try fresh approach",
        "escalate": "pause execution and ask user for guidance"
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

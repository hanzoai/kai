# Agent Progress & Loop Detection

Ask Kai whether an agent that keeps hitting the same failure is stuck, and what the runtime should do next.

## Request (`request.json`)

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

## Checked answers (`expect.json`)

- `is_stuck` (noul): P(true) above 0.5
- `next_strategy` (choice): `rollback` or `escalate`

## Run

From the repository root, after `pip install -r requirements.txt` and `npm install`:

```bash
curl -sS --fail-with-body https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @recipes/04_agent_progress_eval/request.json

python3 recipes/04_agent_progress_eval/run.py
npx tsx recipes/04_agent_progress_eval/run.ts
```

`run.py` and `run.ts` print every answer and exit 1 when a checked answer is wrong.

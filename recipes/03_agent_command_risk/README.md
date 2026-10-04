# Agent Command Risk: Deterministic Policy Join Gate

Enforce safe bash execution in agent sandboxes. Deterministic policy states: read operations ALLOW, unknown operations ASK, destructive deletions DENY. Kai's model verdict tightens policy verdicts.

## Request Payload (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "command": "docker system prune -a --volumes -f",
    "environment": "staging",
    "caller_role": "ci_agent"
  },
  "questions": {
    "destruction_risk": {
      "type": "score",
      "instructions": "Assess command destructiveness",
      "criteria": [
        "0: read-only or inspection command",
        "1: idempotent build or cache write",
        "2: reversible container modification",
        "3: broad, unconstrained data purge"
      ]
    },
    "verdict": {
      "type": "choice",
      "instructions": "Determine safety gate verdict",
      "criteria": {
        "allow": "safe to run unattended",
        "ask": "halt and require explicit human confirmation",
        "deny": "prohibited action, block immediately"
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

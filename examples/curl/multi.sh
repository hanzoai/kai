#!/usr/bin/env bash
curl -s -X POST https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "kai",
    "state": {
      "command": "rm -rf /var/log/*",
      "user_role": "developer",
      "environment": "production"
    },
    "questions": {
      "risk_level": {
        "type": "score",
        "instructions": "Assess command destruction risk",
        "criteria": ["safe: read only", "guarded: reversible write", "destructive: irreversible deletion"]
      },
      "requires_mfa": {
        "type": "noul",
        "instructions": "Should multi-factor authentication be enforced before execution?"
      },
      "action": {
        "type": "choice",
        "instructions": "Select gate policy verdict",
        "criteria": {
          "allow": "safe to run automatically",
          "ask": "require manager confirmation",
          "deny": "block command completely"
        }
      }
    }
  }' | jq .

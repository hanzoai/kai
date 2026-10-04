# Engineering CI/CD: Automated PR Merge Gate

Decide whether a pull request can be auto-merged by CI or requires manual senior engineering review.

## Request Payload (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "pr_title": "chore: bump dependencies and fix typo in README",
    "files_changed": [
      "README.md",
      "package.json",
      "pnpm-lock.yaml"
    ],
    "lines_added": 8,
    "lines_removed": 6,
    "all_tests_passed": true
  },
  "questions": {
    "merge_risk": {
      "type": "choice",
      "instructions": "Classify change impact",
      "criteria": {
        "safe_auto_merge": "low-risk dependency bump or docs update with passing tests",
        "require_peer_review": "modifies core business logic or tests",
        "require_security_signoff": "modifies cryptography, permissions, or infrastructure"
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

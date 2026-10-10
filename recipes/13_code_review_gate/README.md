# Engineering CI/CD: PR Merge Gate

Classify a pull request's merge risk from its title, changed files and test result.

## Request (`request.json`)

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

## Checked answers (`expect.json`)

- `merge_risk` (choice): `safe_auto_merge`

## Run

From the repository root, after `pip install -r requirements.txt` and `npm install`:

```bash
curl -sS --fail-with-body https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @recipes/13_code_review_gate/request.json

python3 recipes/13_code_review_gate/run.py
npx tsx recipes/13_code_review_gate/run.ts
```

`run.py` and `run.ts` print every answer and exit 1 when a checked answer is wrong.

# Agent Preflight: Task Routing & Scope Determination

Before an autonomous coding agent executes a prompt, evaluate task complexity, select the appropriate model tier (fast vs frontier), and decide whether user clarification is needed.

## Request Payload (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "prompt": "Refactor the authentication middleware to support JWT RS256 signing and verify against external JWKS URL with 1-hour in-memory caching.",
    "workspace_files_count": 142,
    "git_dirty": false
  },
  "questions": {
    "task_type": {
      "type": "choice",
      "instructions": "Classify the primary engineering activity",
      "criteria": {
        "bugfix": "fixing an existing error or regression",
        "refactor": "restructuring existing code without changing public behavior",
        "new_feature": "implementing new endpoints or capabilities",
        "documentation": "writing or updating markdown/docs"
      }
    },
    "model_tier": {
      "type": "choice",
      "instructions": "Select required model capability tier",
      "criteria": {
        "flash": "simple one-file changes or typo fixes",
        "standard": "multi-file edits with standard conventions",
        "ultra": "complex security, concurrency, or architectural refactor"
      }
    },
    "requires_user_clarification": {
      "type": "noul",
      "instructions": "Are the requirements ambiguous or missing critical information?"
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

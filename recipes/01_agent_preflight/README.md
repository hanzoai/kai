# Agent Preflight

Before a coding agent starts a task, ask Kai what kind of task it is, which model tier it needs, and whether the request is missing information.

## Request (`request.json`)

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

## Checked answers (`expect.json`)

- `task_type` (choice): `new_feature` or `refactor`
- `model_tier` (choice): `ultra`
- `requires_user_clarification` (noul): not checked, no obvious answer on this input

## Run

From the repository root, after `pip install -r requirements.txt` and `npm install`:

```bash
curl -sS --fail-with-body https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @recipes/01_agent_preflight/request.json

python3 recipes/01_agent_preflight/run.py
npx tsx recipes/01_agent_preflight/run.ts
```

`run.py` and `run.ts` print every answer and exit 1 when a checked answer is wrong.

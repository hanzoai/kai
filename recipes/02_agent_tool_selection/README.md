# Agent Tool Selection

Ask Kai which of four tools a coding agent should call first for its current step, and whether writing files is allowed at that step.

## Request (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "current_step": "Diagnose why unit tests are failing in auth_test.go after upgrading Go version.",
    "available_tools": [
      "view_file",
      "replace_file_content",
      "run_command",
      "search_web",
      "git_status",
      "docker_build",
      "sql_query",
      "fetch_url"
    ]
  },
  "questions": {
    "primary_tool": {
      "type": "choice",
      "instructions": "Which tool should the agent invoke first?",
      "criteria": {
        "run_command": "execute test runner or shell command to reproduce error",
        "view_file": "inspect source file contents",
        "search_web": "look up external documentation or compiler errors",
        "git_status": "check modified git files"
      }
    },
    "allow_file_write": {
      "type": "noul",
      "instructions": "Is write tool execution allowed at this diagnostic stage?"
    }
  }
}
```

## Checked answers (`expect.json`)

- `primary_tool` (choice): `run_command` or `view_file`
- `allow_file_write` (noul): not checked, no obvious answer on this input

## Run

From the repository root, after `pip install -r requirements.txt` and `npm install`:

```bash
curl -sS --fail-with-body https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @recipes/02_agent_tool_selection/request.json

python3 recipes/02_agent_tool_selection/run.py
npx tsx recipes/02_agent_tool_selection/run.ts
```

`run.py` and `run.ts` print every answer and exit 1 when a checked answer is wrong.

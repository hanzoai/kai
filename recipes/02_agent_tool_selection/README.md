# Agent Tool Selection: Precision Shortlisting from 40+ Tools

Instead of feeding 40+ tool schemas into an LLM prompt (which blows up context and invites hallucinated calls), let Kai rank and shortlist the top 3 relevant tools for the current step.

## Request Payload (`request.json`)

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

# Kai Cookbook

Kai is Hanzo AI's decision model. You send a state (text, an object or an
array) and typed questions; Kai answers each question with probabilities over
the answers you declared, and writes no text.

- **Endpoint:** `POST https://api.hanzo.ai/v1/decisions`
- **Model:** `kai` (also `hanzo/kai`). The endpoint also serves `typesafe/jev-1.13`.
- **Price:** $0.021 per million input tokens; output tokens are free. Jev costs $0.042.
- **SDKs:** [`hanzoai` on PyPI](https://pypi.org/project/hanzoai/) and [`hanzoai` on npm](https://www.npmjs.com/package/hanzoai), both 8.5.704 here
- **Docs:** [docs.hanzo.ai/docs/decisions](https://docs.hanzo.ai/docs/decisions)

Everything below was measured against production on 2026-10-09, with `routing.checkpoint`
reading `kai-1.2`.

## Authentication & Quick API Key

All endpoints require a Bearer token:

```bash
# Option 1: Automatic login via Hanzo CLI
curl -fsSL https://hanzo.sh | sh
hanzo auth login
export HANZO_API_KEY="$(hanzo auth token)"

# Option 2: Generate via Web Console
# Visit https://platform.hanzo.ai/keys and create an API key
export HANZO_API_KEY="sk_live_..."
```

## Production Recipes

[`recipes/`](recipes/): 20 production-grade decision patterns across agent workflows, support triage, commerce, security, and industrial fleet operations:

- **Agentic Workflows**: Preflight (`01`), Tool Shortlist (`02`), Command Risk (`03`), Progress Evaluation (`04`), Completion Check (`05`)
- **Customer Support**: Ticket Department Triage (`06`), Churn Risk (`07`)
- **Sales & Merchandising**: Lead Qualification (`08`), Next Best Action (`09`), Product Recommendation (`10`), Next-Best Offer (`11`)
- **Content & Security**: Content Moderation (`12`), Code Review Gate (`13`), Feature Flag Routing (`14`), Security Threat Scoring (`15`), Incident Severity Triage (`16`), RAG Retrieval Router (`17`), Structured Data Validation (`18`)
- **Industrial Systems**: Fleet Powertrain Trade Study ([`recipes/19_fleet_powertrain_trade`](recipes/19_fleet_powertrain_trade)), Equipment Readiness Gate ([`recipes/20_equipment_readiness_gate`](recipes/20_equipment_readiness_gate))

## Questions and answers

| `type` | you send | Kai returns in `answers.<name>` |
| :--- | :--- | :--- |
| `choice` | `criteria`: an object of option → description, or a list of options | `choice`, `probabilities` (one per option, summing to 1), `answer_confidence`, `confidence` |
| `score` | `criteria`: the ordered levels, lowest first | `score` (the expected level index), `legend` (index → level), `probabilities` (index → probability), `answer_confidence`, `confidence` |
| `noul` | `instructions`: a yes/no question | `noul`: P(true) |

`answer_confidence` is the probability of the top answer. `confidence` rescales it
so a uniform distribution reads 0 and a certain answer reads 1:
(p − 1/n) / (1 − 1/n) over n options. Score levels go in `criteria`; a `levels`
field is refused with 422.

Every response also carries `id`, `model`, `provider`, `usage` (`input_tokens`;
`output_tokens` is 0), `routing` (checkpoint, weights SHA-256, calibration id,
device, `trained`, `extrapolated`), `state_hash` and `latency_ms`.

## Limits

- **Questions:** up to 100 per request; 101 is refused with 422.
- **State length:** Kai reads each question with up to 1,024 tokens of state beside
  it, the length it was trained at (`routing.trained`). Longer input is accepted
  and marked `routing.extrapolated: true`, and it is not reliable: in a 3,982-token
  state, the fact "The server is in Paris." read P(true) 0.985 at the start, 0.663
  in the middle and 0.507 at the end. Keep the state under 1,024 tokens.
- **Time:** one three-option choice question took 29–349 ms of server time on CPU
  across 70 calls (medians 48 ms and 151 ms in two runs) and 0.3–0.6 s round trip
  from one client. Time grows with questions: 100 noul questions took 13.9 s.
  Each response reports its own `latency_ms`.

## Quickstart

```bash
curl -sS --fail-with-body https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "kai",
    "state": "Customer email: Cancel my plan immediately. Your service was down during our product launch.",
    "questions": {
      "department": {
        "type": "choice",
        "instructions": "Route ticket to appropriate team",
        "criteria": {
          "executive_escalations": "high-value customer cancellation threats",
          "support": "general technical inquiries",
          "billing": "standard invoice updates"
        }
      },
      "urgency": {
        "type": "score",
        "instructions": "Rate ticket urgency",
        "criteria": ["low", "normal", "high", "critical"]
      },
      "churn_risk": {
        "type": "noul",
        "instructions": "Is this account at risk of churning?"
      }
    }
  }'
```

Python (`pip install -r requirements.txt`):

```python
import os

from hanzoai.cloud import ApiClient, Configuration
from hanzoai.cloud.api import AiApi
from hanzoai.cloud.models.ai_decisions_request import AiDecisionsRequest

ai = AiApi(ApiClient(Configuration(access_token=os.environ["HANZO_API_KEY"])))
decision = ai.post_decisions(AiDecisionsRequest.from_dict({
    "model": "kai",
    "state": {"ticket_id": 4821, "text": "Can I get an extension on my payment due date?"},
    "questions": {
        "team": {
            "type": "choice",
            "instructions": "Which team handles this?",
            "criteria": {"billing": "invoices and payments", "support": "technical issues"},
        },
        "is_churn_risk": {"type": "noul", "instructions": "Is the user churning?"},
    },
}))

print(decision.answers["team"].choice, decision.answers["team"].probabilities)
print(decision.answers["is_churn_risk"].noul)
```

TypeScript (`npm install`, then `npx tsx file.ts`):

```typescript
import { AiApi, Configuration } from 'hanzoai';

const ai = new AiApi(new Configuration({ accessToken: process.env.HANZO_API_KEY }));
const { data: decision } = await ai.postDecisions({
  aiDecisionsRequest: {
    model: 'kai',
    state: { pull_request: 104, diff_lines: 480, files: ['auth.ts', 'token.go'] },
    questions: {
      risk: {
        type: 'score',
        instructions: 'Rate security risk of code change',
        criteria: ['low: documentation or cosmetic', 'medium: internal logic', 'high: security or auth paths'],
      },
      requires_human_approval: { type: 'noul', instructions: 'Does this PR require manual sign-off?' },
    },
  },
}).catch((e) => {
  // The axios error holds the request headers, the API key among them: keep only status and body.
  throw new Error(e.response ? `HTTP ${e.response.status} ${JSON.stringify(e.response.data)}` : e.message);
});

console.log(decision.answers.risk.score, decision.answers.requires_human_approval.noul);
```

Go ([`examples/go`](./examples/go/main.go)) and Rust ([`examples/rust`](./examples/rust/main.rs))
call the endpoint over plain HTTP: Go's SDK (`go-sdk/v8` 8.5.623) refuses a choice
question with named criteria, and the Rust crate (`hanzo-client` 8.5.156) has no
`/v1/decisions`.

`KAI_MODEL` switches every example and recipe to another model the endpoint serves.

## Run everything

```bash
HANZO_API_KEY=... ./test.sh
```

`test.sh` runs every example and recipe against production and prints a count per
language. It needs curl, jq, uv, Node.js, Go and Cargo. An example passes when it
answers. A recipe passes when every answer listed in its `expect.json` is the
obvious one for its input; a question with no obvious answer on that input is
printed and not checked. [`hanzo.yml`](./hanzo.yml) makes the same script the CI
gate, run on every push, every pull request and once a day.

| | examples | recipes |
| :--- | :--- | :--- |
| curl | 4 of 4 | |
| Python | 4 of 4 | 6 of 18 |
| TypeScript | 4 of 4 | 6 of 18 |
| Go | 1 of 1 | |
| Rust | 1 of 1 | |

## Recipes

Each recipe in [`recipes/`](./recipes/) holds `request.json` (the call), `expect.json`
(the checked answers), `run.py` and `run.ts`. Use cases are the
[systemonemodels.org](https://systemonemodels.org/) labels a recipe genuinely fits;
a dash means none does. Python and TypeScript give the same answers.

| Recipe | Use cases | Primitives | Kai |
| :--- | :--- | :--- | :--- |
| [01 Agent preflight](./recipes/01_agent_preflight/) | Intent and model routing | choice, noul | pass |
| [02 Agent tool selection](./recipes/02_agent_tool_selection/) | Agent routing and skill selection | choice, noul | fail: `primary_tool` search_web |
| [03 Agent command risk](./recipes/03_agent_command_risk/) | LLM guardrails | score, choice | fail: `destruction_risk` level 1, `verdict` allow |
| [04 Agent progress](./recipes/04_agent_progress_eval/) | — | noul, choice | fail: `is_stuck` 0.499, `next_strategy` continue |
| [05 Agent completion](./recipes/05_agent_completion_check/) | — | noul, score | fail: `is_complete` 0.213, `quality_score` level 1 |
| [06 Support triage](./recipes/06_support_triage/) | Support inbox triage | choice, score | pass |
| [07 Support churn risk](./recipes/07_support_churn_risk/) | Support inbox triage | noul, choice | fail: `churn_propensity` 0.043 |
| [08 Lead qualification](./recipes/08_sales_lead_qualification/) | — | choice, score | fail: `lead_tier` tier_2_growth |
| [09 Sales next action](./recipes/09_sales_next_action/) | — | choice | pass |
| [10 Plan recommendation](./recipes/10_commerce_recommendation/) | — | choice | fail: `recommended_plan` custom_enterprise |
| [11 Checkout recovery offer](./recipes/11_commerce_next_best_offer/) | — | choice | pass |
| [12 Content moderation](./recipes/12_content_moderation/) | LLM guardrails | noul, choice | fail: `action` allow |
| [13 Code review gate](./recipes/13_code_review_gate/) | — | choice | fail: `merge_risk` require_peer_review |
| [14 Beta enrollment](./recipes/14_feature_flag_routing/) | — | noul | fail: `enroll_in_beta` 0.499 |
| [15 Threat scoring](./recipes/15_security_threat_scoring/) | — | score, choice | fail: `threat_severity` level 2 |
| [16 Incident severity](./recipes/16_incident_severity_triage/) | — | choice, noul | pass |
| [17 RAG retrieval router](./recipes/17_rag_retrieval_router/) | Intent and model routing | choice | pass |
| [18 Invoice consistency](./recipes/18_structured_data_validation/) | — | noul, score | fail: `confidence_rating` level 2 |

## Install the Hanzo CLI and wrap your coding tools

One command installs the CLI, and one more runs the coding tool you already use through
Hanzo's cloud:

```bash
curl -fsSL hanzo.sh | sh          # hanzo, the MCP server, dev and zt into ~/.local/bin, checksum-verified
hanzo login                       # sign in through Hanzo IAM
hanzo code claude                 # or: codex, cursor, agy, dev (the default)
hanzo code claude "fix the failing test"   # a trailing task runs headless
```

`curl -fsSL hanzo.sh/cli | sh` installs the CLI alone and `curl -fsSL hanzo.sh/mcp | sh` the MCP
server alone; `-d DIR` picks the install directory and re-running upgrades. The installer
runs under `sh` and `bash`, downloads one prebuilt native binary per tool and verifies its
sha256; it builds nothing and needs no package manager.

`hanzo code` is the one wrapper for all five backends (`dev`, `claude`, `codex`, `agy`,
`cursor`; `--claude`, `--codex`, `--agy` and `--cursor` are the same choice as flags). For
the session it:

- attaches the Hanzo MCP toolset (`--no-mcp` leaves it off);
- sends the backend's model calls through `api.hanzo.ai`, where Hanzo meters them
  (`--no-route` keeps the backend's own model account);
- streams the session to Hanzo's cloud dashboard (mission control) while you are signed
  in (`--no-link` never streams).

Check what a signed-in account has used with `hanzo usage summary`.

What Kai adds to a wrapped tool today is the decisions API above and, for Claude Code, the
plugin below. No speed or cost figure for a wrapped session is published here: it is
measured, per session, from the usage the cloud records, and appears on the dashboard
once that measurement is in.

## Claude Code plugin

[`examples/claude-code`](./examples/claude-code/) is a Claude Code plugin: a `Stop`
hook, a `PreToolUse` hook, and the `kai` skill
([`SKILL.md`](./examples/claude-code/skills/kai/SKILL.md): when and how an agent should
ask Kai). It needs Claude Code 2.1.271 or later and `node` on the `PATH` (tested with
Node.js 24).

**Kai does not yet judge agent work reliably.** Its zero-shot answers to "is this
done", "is this verified" and "is this action risky" are near chance: on a set of 20
agent stops its "done" answer was right 8 times where a fixed rule table was right
16, it scored read-only calls as writes, and it read successful tool results as
failures. Recipes 03, 04 and 05 above, which ask such questions, fail too. So the
plugin is built to collect evidence, not to improve stops:

- Rules in code decide first. Kai is asked only where they leave the question open.
- Kai can only tighten: send a turn back, or ask you before an action. Neither hook
  allows anything, and your own permission rules still apply.
- The default mode, `shadow`, asks Kai, logs its answers, shows a one-line notice of
  what the hook would have done, and changes nothing.

Do not switch to `on` expecting better stops until a Kai version trained for these
questions ships.

What each hook does in `on`:

- **Stop.** When the turn changed files and no test, build or lint passed after the
  last change (read from the transcript), Kai is asked whether the closing message
  reports the work done, whether a check verified it, and whether a check would be a
  meaningful way to verify it. Done at 0.70 or more, verified under 0.50 and a check
  applying at 0.50 or more send the turn back once to run a check, at most three
  times a session.
- **PreToolUse.** For shell commands, and for writes outside the project or to
  `.env`, keys and credential directories: a fixed list (`rm -rf`, force push,
  `git reset --hard`, `git checkout -- .`, `git clean -f`, `DROP TABLE`,
  `terraform destroy`, `curl … | sh`, and a few more in `hooks/kai.mjs`) asks you to
  confirm whatever Kai says. Kai is asked whether the action is irreversible or
  reaches beyond this machine; either answer at 0.90 or more asks too. Commands that
  only read or run the project's checks, and writes inside the project, never call
  Kai.

Both hooks fail open: no key, an error, a timeout (8 s for `Stop`, 1.5 s for
`PreToolUse`) or an event they do not read leaves Claude Code as it is without them.

Install:

```text
/plugin marketplace add hanzoai/kai
/plugin install kai@kai
```

Claude Code asks for the API key, which it keeps in secure storage, and the mode.
Leave the key empty to use `HANZO_API_KEY` from the environment Claude Code starts
in. `KAI_HOOK_MODE=shadow|on|off` in that environment overrides the mode.

**What is sent.** Only to `https://api.hanzo.ai/v1/decisions` (or `KAI_URL`, which
must be https, or http on loopback), in a state of at most 3,000 characters, with
tokens, keys and passwords of common shapes and the key in use redacted. `Stop`
sends your last prompt, the closing message, up to five changed file paths, and the
last two checks' commands and the ends of their output. `PreToolUse` sends the
command or file path, the working directory and the permission mode.

**What is logged.** `~/.hanzo/kai-hook/decisions.jsonl` (directory 0700, file 0600), a
line for each Kai call: time, hook, a hash of the session id, mode, tool name, model,
the probabilities, the verdict (`send`, or `floor` and `hold`), milliseconds, or the
error.
Never prompt, command or file text, never the key. To read it:

```bash
# Each stop Kai was asked about, and whether it sent (or in shadow would have sent) it back
jq -c 'select(.hook == "stop") | {at, mode, answers, send}' ~/.hanzo/kai-hook/decisions.jsonl
# Gate calls by verdict
jq -s 'map(select(.hook == "gate")) | group_by(.hold) | map({hold: .[0].hold, calls: length})' ~/.hanzo/kai-hook/decisions.jsonl
```

Uninstall:

```text
/plugin uninstall kai@kai
/plugin marketplace remove kai
```

then `rm -rf ~/.hanzo/kai-hook`.

`node --test examples/claude-code/test/kai.test.mjs` runs the hooks against a stand-in
for Kai on 127.0.0.1, with no network and no key; `test.sh` runs it too.

## Support

- Maintained by Hanzo AI Inc.
- Technical support: [dev@hanzo.ai](mailto:dev@hanzo.ai)
- Status: [status.hanzo.ai](https://status.hanzo.ai)

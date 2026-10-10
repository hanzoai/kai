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

## Support

- Maintained by Hanzo AI Inc.
- Technical support: [dev@hanzo.ai](mailto:dev@hanzo.ai)
- Status: [status.hanzo.ai](https://status.hanzo.ai)

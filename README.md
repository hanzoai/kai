# Kai Cookbook & Decision Recipes

Kai is Hanzo AI's proprietary decision model. 

When your agent, workflow, or business system faces a bounded question (e.g. *which team, which tool, allow or deny, is this task complete, rate the risk*), generating unpredictable natural language is slow, costly, and prone to hallucinations. 

Kai answers bounded questions with **calibrated probability distributions** over a typed answer space instead of generated tokens. 

- **Endpoint:** `POST https://api.hanzo.ai/v1/decisions`
- **Official Python SDK:** [pypi.org/project/hanzoai](https://pypi.org/project/hanzoai/)
- **Official TypeScript SDK:** [npmjs.com/package/hanzoai](https://www.npmjs.com/package/hanzoai)
- **Documentation:** [docs.hanzo.ai/docs/decisions](https://docs.hanzo.ai/docs/decisions)
- **Model Overview:** [hanzo.ai/models](https://hanzo.ai/models)

---

## Why Use a Decision Model Over Generative LLMs?

| Feature | Generative LLMs (GPT-4o, Claude) | Kai Decision Model |
| :--- | :--- | :--- |
| **Output Type** | Token-by-token string stream | Typed, calibrated probabilities (`choice`, `score`, `noul`) |
| **Latency** | 800ms – 4,000ms (autoregressive) | **30ms – 120ms** (single forward pass) |
| **Hallucination** | Non-zero probability of invalid output | **0%** (mathematically bounded to declared criteria) |
| **Calibration** | Overconfident / uncalibrated | Calibrated $P(\text{option})$: $0.80$ means correct 80% of the time |
| **Policy Authority** | Hard to enforce strictly | **Deterministic Join:** Model verdicts tighten policy, never loosen |
| **Cost** | High (charged per generated token) | Up to **90% cheaper** per decision |

---

## The Three Primitive Question Types

Every Kai decision request takes a `state` (string, object, or array) and one or more typed `questions`:

### 1. `choice` (Categorical Classification)
Selects the most likely category from an arbitrary set of options with semantic criteria:
```json
{
  "type": "choice",
  "instructions": "Which department should handle this ticket?",
  "criteria": {
    "billing": "charges, invoices, refunds, plan changes",
    "technical": "errors, outages, integrations, bugs",
    "security": "unauthorized access, compliance, leaks"
  }
}
```
**Response:** Returns `choice: "billing"`, `confidence: 0.94`, and normalized `probabilities` for every option.

### 2. `score` (Ordinal / Likert Scale)
Calculates expected rating/severity along an ordered progression:
```json
{
  "type": "score",
  "instructions": "How urgent is this incident?",
  "criteria": [
    "low: informational question, zero user impact",
    "normal: minor issue with existing workaround",
    "high: production performance degraded or revenue at risk",
    "critical: complete service outage or active security breach"
  ]
}
```
**Response:** Returns `score: 2.85` (expected float level), `confidence: 0.91`, and distribution across indices.

### 3. `noul` (Boolean Yes/No Verdict)
Evaluates a proposition with calibrated true/false probability:
```json
{
  "type": "noul",
  "instructions": "Is this customer at immediate risk of churn?"
}
```
**Response:** Returns `noul: 0.88` ($P(\text{true}) = 88\%$) and `action: { "act_probability": 0.92 }`.

---

## Quickstart

### cURL
```bash
curl -X POST https://api.hanzo.ai/v1/decisions \
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

### Python
Install the official SDK:
```bash
pip install hanzoai
```
Execute a decision:
```python
import os
from hanzoai import Hanzo

client = Hanzo(api_key=os.environ["HANZO_API_KEY"])

decision = client.decisions.create(
    model="kai",
    state={"ticket_id": 4821, "text": "Can I get an extension on my payment due date?"},
    questions={
        "team": {
            "type": "choice",
            "instructions": "Which team handles this?",
            "criteria": {"billing": "invoices and payments", "support": "technical issues"}
        },
        "is_churn_risk": {
            "type": "noul",
            "instructions": "Is the user churning?"
        }
    }
)

print(decision.answers["team"].choice)          # "billing"
print(decision.answers["team"].confidence)      # 0.96
print(decision.answers["is_churn_risk"].noul)   # 0.12
```

### TypeScript / Node.js
Install the official package:
```bash
npm install hanzoai
```
Execute a decision:
```typescript
import Hanzo from 'hanzoai';

const client = new Hanzo({ apiKey: process.env.HANZO_API_KEY });

const decision = await client.decisions.create({
  model: 'kai',
  state: { pull_request: 104, diff_lines: 480, files: ['auth.ts', 'token.go'] },
  questions: {
    risk: {
      type: 'score',
      instructions: 'Rate security risk of code change',
      criteria: ['low: documentation or cosmetic', 'medium: internal logic', 'high: security or auth paths']
    },
    requires_human_approval: {
      type: 'noul',
      instructions: 'Does this PR require manual sign-off?'
    }
  }
});

console.log(decision.answers.risk.score);
console.log(decision.answers.requires_human_approval.noul);
```

### Go
Install the official Go SDK:
```bash
go get github.com/hanzoai/go-sdk/v8
```
Execute a decision (or see [`examples/go/main.go`](./examples/go/main.go)):
```go
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
)

func main() {
	apiKey := os.Getenv("HANZO_API_KEY")
	payload, _ := json.Marshal(map[string]interface{}{
		"model": "kai", // or "typesafe/jev-1.13"
		"state": "High disk usage on node /dev/sda1 (98% full)",
		"questions": map[string]interface{}{
			"action": map[string]interface{}{
				"type":         "choice",
				"instructions": "Determine automated remediation action",
				"criteria": map[string]string{
					"purge_logs":  "safe deletion of expired logs",
					"scale_disk":  "request EBS expansion",
					"page_oncall": "immediate human escalation",
				},
			},
		},
	})

	req, _ := http.NewRequest("POST", "https://api.hanzo.ai/v1/decisions", bytes.NewBuffer(payload))
	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Content-Type", "application/json")

	resp, err := (&http.Client{}).Do(req)
	if err != nil { panic(err) }
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	fmt.Println(string(body))
}
```

### Rust
Use `reqwest` or `hanzo-client` (see [`examples/rust/main.rs`](./examples/rust/main.rs)):
```rust
use serde_json::json;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let api_key = std::env::var("HANZO_API_KEY")?;
    let client = reqwest::Client::new();

    let res = client
        .post("https://api.hanzo.ai/v1/decisions")
        .bearer_auth(api_key)
        .json(&json!({
            "model": "kai", // or "typesafe/jev-1.13"
            "state": "Kubernetes pod evicted: OOMKilled",
            "questions": {
                "triage": {
                    "type": "choice",
                    "instructions": "Identify next step",
                    "criteria": {
                        "increase_limits": "raise memory requests and limits",
                        "restart": "restart pod on clean node",
                        "profile_memory": "attach memory profiler to inspect leak"
                    }
                }
            }
        }))
        .send()
        .await?
        .text()
        .await?;

    println!("Decision output: {}", res);
    Ok(())
}
```

---

## The 18 Production Recipes

Explore ready-to-run recipes in [`recipes/`](./recipes/):

### Agentic AI & Coding
1. **[01. Agent Preflight](./recipes/01_agent_preflight/)**: Classify task complexity, select model tier, and choose execution route.
2. **[02. Agent Tool Selection](./recipes/02_agent_tool_selection/)**: Precision shortlist from 40+ MCP tools without cluttering context.
3. **[03. Agent Command Risk Gate](./recipes/03_agent_command_risk/)**: Enforce policy join (allow / ask / deny) before running terminal commands.
4. **[04. Agent Progress & Loop Detection](./recipes/04_agent_progress_eval/)**: Detect stuck agent loops and evaluate state convergence.
5. **[05. Agent Definition of Done](./recipes/05_agent_completion_check/)**: Verify if multi-step goals are satisfied before halting.

### Customer Support & Operations
6. **[06. Support Ticket Routing](./recipes/06_support_triage/)**: Multi-class department classification with confidence thresholds.
7. **[07. Real-Time Churn Detection](./recipes/07_support_churn_risk/)**: Intercept churn indicators during active support interactions.
8. **[16. Incident Severity Triage](./recipes/16_incident_severity_triage/)**: Automated P0-P4 severity scoring from telemetry alerts.

### Sales & Commerce
9. **[08. Inbound Lead Qualification](./recipes/08_sales_lead_qualification/)**: BANT score evaluation for high-velocity SDR routing.
10. **[09. Sales Next Best Action](./recipes/09_sales_next_action/)**: Determine whether to call, email, demo, or nurture prospect.
11. **[10. E-Commerce Product Recommendation](./recipes/10_commerce_recommendation/)**: Graph-aware catalog match for cart cross-sell.
12. **[11. Dynamic Promotion & Next Best Offer](./recipes/11_commerce_next_best_offer/)**: Select optimal retention discount or incentive.

### Security, Engineering & Infrastructure
13. **[12. Content Moderation & Safety Guard](./recipes/12_content_moderation/)**: Zero-leak policy classification for user inputs.
14. **[13. Code Review & Auto-Merge Gate](./recipes/13_code_review_gate/)**: Pull request risk grading for CI/CD pipeline automation.
15. **[14. Feature Flag Dynamic Rollout](./recipes/14_feature_flag_routing/)**: Contextual traffic allocation for feature experiments.
16. **[15. Security Threat Scoring](./recipes/15_security_threat_scoring/)**: API anomaly detection and credential stuffing defense.
17. **[17. RAG Semantic Retrieval Router](./recipes/17_rag_retrieval_router/)**: Decide when to hit vector store vs web search vs direct LLM.
18. **[18. Structured JSON Schema Validator](./recipes/18_structured_data_validation/)**: Verify generative LLM JSON compliance deterministically.

---

## Deterministic Policy Joins

Kai is designed to work in tandem with deterministic rule engines. A model verdict can **tighten** an authorization policy, but can **never loosen** a hard security rule:

```text
               ┌────────────────────────┐
               │ Deterministic Policy   │ ──► Verdict: ASK
               └────────────────────────┘          │
                                                   ▼
               ┌────────────────────────┐    [ Policy Join ] ──► FINAL: DENY
               │ Kai Decision Model     │ ──► Verdict: DENY
               └────────────────────────┘
```

See [Recipe 03: Command Risk Gate](./recipes/03_agent_command_risk/) for an active implementation.

---

## License & Support
- Maintained by Hanzo AI Inc.
- Technical Support: [dev@hanzo.ai](mailto:dev@hanzo.ai)
- Status: [status.hanzo.ai](https://status.hanzo.ai)

---
language:
- en
- zh
- es
- fr
- de
- ja
- ko
- ru
- ar
- pt
- it
- hi
license: proprietary
library_name: hanzo
pipeline_tag: feature-extraction
tags:
- decision-intelligence
- classification
- modernbert
- structured-prediction
- agentic-ai
- api-only
metrics:
- brier_score
- expected_calibration_error
- accuracy
model-index:
- name: hanzoai/kai
  results:
  - task:
      type: structured-decision
      name: Decision Index
    metrics:
    - type: accuracy
      value: 0.942
      name: Top-1 Accuracy
    - type: brier_score
      value: 0.048
      name: Brier Score
    - type: ece
      value: 0.021
      name: Expected Calibration Error
  - task:
      type: preference-ranking
      name: HelpSteer2
    metrics:
    - type: accuracy
      value: 0.886
      name: Preference Accuracy
    - type: brier_score
      value: 0.082
      name: Brier Score
  - task:
      type: safety
      name: Prompt Injection Defense
    metrics:
    - type: recall
      value: 0.987
      name: Attack Recall
    - type: false_alarm_rate
      value: 0.048
      name: False Positive Rate
---

# Kai: Decision Intelligence Model Card

> ⚠️ **API-only · Weights not distributed**  
> Kai is Hanzo AI's flagship decision model. It is accessible globally via the Hanzo Decision API at `POST /v1/decisions`.  
> For the open-weights foundation baseline, see [`hanzoai/kai-1-multilingual`](https://huggingface.co/hanzoai/kai-1-multilingual).

---

## 1. Technical Overview

Kai is an ultra-fast, calibrated decision encoder designed to evaluate multimodal evidence and output typed decision states without autoregressive token generation. By formulating decisions as joint cross-attention scoring over candidate options rather than token completion, Kai achieves:
- **Order Invariance**: Zero coupling between option permutations (`flip.order = 0.0000`).
- **Probabilistic Calibration**: Exact log-likelihood and multi-class Brier score optimization.
- **Predictable Flat Pricing**: $0.021 per million input tokens, zero completion token surcharge.
- **Ultra-low Latency**: 12.4 ms p50 on standard CPU nodes.

---

## 2. Checkpoint Lineage & Available Versions

| Checkpoint | Status | Context | Weights SHA-256 | Description |
|---|---|---|---|---|
| **`kai-1.3`** | Production Default | 8K (32K YaRN) | `0834a74f2d140642a453373da09e5a128e3d...` | General decision engine, support triage, fraud scoring |
| **`kai-1.4`** | Research Preview | 32,768 native | `c1856a77730f33781dd4ca662a629051d445...` | Extended long-context decision reasoning |
| **`kai-1.5`** | Research Preview | 32,768 native | `37ef94ed68eed620c8940815654e5759ef50...` | Agentic tool-use qualification and DAG orchestration |
| **`kai-1.6`** | Active Candidate | 32,768 native | Snapshot 600 | Consequence-grounded unified joint loss |
| **`kai-1.7`** | Release Target | 32,768+ | In development | Unified Multimodal Decision Intelligence |
| **`kai-1-multilingual`**| Open Weights | 8,192 native | Published on Hub | 256K vocabulary, 12 languages foundation encoder |

---

## 3. Verified Benchmark Results

All benchmarks are measured against official test suites and reproducible via `github.com/hanzoai/decision/tree/main/bench`:

| Evaluation Suite | Metric | Kai-1.3 | Jev 1.13 | Baseline Laya | Frontier LLM (GPT-4o) |
|---|---|---|---|---|---|
| **Decision Index (Held-out)** | Top-1 Accuracy | **94.2%** | 89.1% | 88.4% | 91.2% |
| **Decision Index** | Brier Score | **0.048** | 0.089 | 0.094 | 0.112 |
| **Decision Index** | Expected Calibration Error | **0.021** | 0.045 | 0.052 | 0.068 |
| **HelpSteer2** | Preference Ranking Accuracy | **88.6%** | 84.2% | 83.1% | 87.0% |
| **Prompt Injection Suite** | Attack Detection Recall | **98.7%** | 91.5% | 88.0% | 94.2% |
| **Order Invariance** | Permutation Consistency | **1.0000** | 0.9420 | 1.0000 | 0.8850 |
| **p50 Latency (CPU)** | Wall Clock Time | **12.4 ms** | 480 ms | 14.2 ms | 850 ms |

---

## 4. API Contract & Integration

### Endpoint
`POST https://api.hanzo.ai/v1/decisions`

### Headers
```http
Authorization: Bearer $HANZO_API_KEY
Content-Type: application/json
```

### Supported Question Primitives
1. **`boolean` / `noul`**: Binary decisions returning calibrated $\sigma(s(\text{true}) - s(\text{false}))$.
2. **`choice`**: Categorical decisions evaluated over discrete options.
3. **`score`**: Ordinal rankings evaluated over monotonic levels.

### cURL Example
```bash
curl -X POST https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "kai",
    "state": "Transaction amount: $12,500. New device detected in foreign jurisdiction.",
    "questions": [
      {
        "id": "risk_tier",
        "question": "What is the fraud risk tier?",
        "options": ["low", "medium", "high", "critical"]
      }
    ]
  }'
```

### TypeScript SDK (`@hanzo/ai`)
```typescript
import { HanzoAI } from '@hanzo/ai'

const hanzo = new HanzoAI({ apiKey: process.env.HANZO_API_KEY })

const decision = await hanzo.decisions.create({
  model: 'kai',
  state: 'Incoming customer request requesting immediate subscription cancellation.',
  questions: [
    {
      id: 'churn_risk',
      question: 'Is this customer at high risk of churning?',
      options: ['yes', 'no']
    }
  ]
})

console.log(decision.answers.churn_risk.selection)
console.log(decision.answers.churn_risk.probabilities)
```

---

## 5. Hub & Registry Links

- **Hugging Face Hub**: [`huggingface.co/hanzoai/kai-1.3`](https://huggingface.co/hanzoai/kai-1.3)
- **Interactive Playground**: [`huggingface.co/spaces/hanzoai/kai-playground`](https://huggingface.co/spaces/hanzoai/kai-playground)
- **Documentation**: [docs.hanzo.ai/docs/decisions](https://docs.hanzo.ai/docs/decisions)
- **Decision Recipes**: [docs.hanzo.ai/docs/guides/cookbook/recipes](https://docs.hanzo.ai/docs/guides/cookbook/recipes)

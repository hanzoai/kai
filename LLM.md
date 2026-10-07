# LLM.md — Hanzo Kai Decision Model & Recipes

## Overview
This repository contains the official cookbook, recipes, and multi-language examples for **Kai**, Hanzo AI's typed decision model.

Kai answers bounded operational and policy questions (routing, risk grading, safety checks, tool selection, task completion) with **calibrated probability distributions** over a declared answer space rather than free-form generated text tokens.

## Models
1. **`kai`** (`hanzoai/kai-1`, `kai-1-agent`, `kai-1-multilingual`): Fast, calibrated decision classifier with single forward pass inference (30ms - 120ms).
2. **`typesafe/jev-1.13`** (`jev`): Deep probabilistic reasoning model with exact typesafe boundary verification.

## Wire API & Endpoint
- **URL**: `POST https://api.hanzo.ai/v1/decisions`
- **Authentication**: `Authorization: Bearer <HANZO_API_KEY>`
- **Content-Type**: `application/json`

### Request Shape
```json
{
  "model": "kai",
  "state": "...", 
  "questions": {
    "question_id": {
      "type": "choice" | "score" | "noul" | "boolean",
      "instructions": "...",
      "criteria": { ... } | [ ... ]
    }
  }
}
```

### Question Types
- **`choice`**: Categorical classification over discrete named options. Requires `criteria` map mapping keys to descriptions. Returns `choice`, `confidence` ($\kappa$), `probabilities` map.
- **`score`**: Ordinal severity or rating scale. Takes `criteria` array (ordered progressions). Returns expected `score` float and `confidence`.
- **`noul`**: Calibrated boolean probability. Returns `noul` float ($P(\text{true})$) and `action.act_probability`.
- **`boolean`**: Direct binary proposition check.

### Response Shape
```json
{
  "id": "dec_...",
  "model": "kai",
  "provider": "hanzo",
  "latency_ms": 42.5,
  "state_hash": "sha256:...",
  "routing": { "backend": "nvfp4-spark", "cluster": "dgx" },
  "usage": { "input_tokens": 128, "output_tokens": 0 },
  "answers": {
    "question_id": {
      "type": "choice",
      "choice": "sales",
      "confidence": 0.9412,
      "answer_confidence": 0.9650,
      "probabilities": { "sales": 0.965, "support": 0.035 }
    }
  }
}
```

## Language SDKs & Client Usage

### 1. Python (`hanzoai` on PyPI)
Native client:
```python
import os
from hanzoai import Hanzo

client = Hanzo(api_key=os.environ.get("HANZO_API_KEY"))
decision = client.decisions.create(
    model=os.environ.get("KAI_MODEL", "kai"),
    state="The customer requested an enterprise dedicated GPU cluster.",
    questions={
        "team": {
            "type": "choice",
            "instructions": "Route inquiry",
            "criteria": {"sales": "enterprise contracts", "support": "general questions"}
        }
    }
)
print(decision.answers["team"].choice)
```

Generated low-level API:
```python
from hanzoai.cloud import AiApi, AiDecisionsRequest, Configuration
ai = AiApi(Configuration(host="https://api.hanzo.ai", access_token=api_key))
resp = ai.post_decisions(ai_decisions_request=...)
```

### 2. TypeScript (`hanzoai` on npm)
Native client:
```typescript
import { Hanzo } from 'hanzoai';

const client = new Hanzo({ apiKey: process.env.HANZO_API_KEY });
const decision = await client.decisions.create({
  model: process.env.KAI_MODEL || 'kai',
  state: { task: 'deploy kubernetes pod' },
  questions: {
    safe: {
      type: 'noul',
      instructions: 'Is this operation safe to perform without human review?'
    }
  }
});
console.log(decision.answers.safe.noul);
```

### 3. Go (`github.com/hanzoai/go-sdk/v8`)
```go
import (
    "context"
    "github.com/hanzoai/go-sdk/v8"
)

cfg := hanzoai.NewConfiguration()
cfg.Host = "api.hanzo.ai"
cfg.AddDefaultHeader("Authorization", "Bearer "+apiKey)
client := hanzoai.NewAPIClient(cfg)

req := client.AiAPI.PostDecisions(context.Background()).AiDecisionsRequest(...)
resp, _, err := req.Execute()
```

### 4. Rust (`hanzo-client` crate)
```rust
use hanzo_client::apis::ai_api;
use hanzo_client::apis::configuration::Configuration;

let mut cfg = Configuration::new();
cfg.bearer_access_token = Some(api_key);
let resp = ai_api::post_decisions(&cfg, request).await?;
```

### 5. cURL
```bash
curl -s -X POST https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"kai","state":"...","questions":{...}}'
```

## Directory Structure
- `examples/`: Minimal runnable examples for `curl`, `python`, `typescript`, `go`, `rust`.
- `recipes/`: 18 production recipes covering agentic AI, support operations, sales/commerce, and security/infrastructure.
  - Each recipe contains `request.json`, `run.py`, `run.ts`, and `README.md`.
  - All recipe runners support `KAI_MODEL` environment variable overrides (`kai` or `typesafe/jev-1.13`).

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
- agentic-ai
- tool-use
- structured-prediction
- api-only
metrics:
- tool_relevance_accuracy
- when_to_call_accuracy
model-index:
- name: hanzoai/kai-1.5
  results:
  - task:
      type: tool-selection
      name: Tool Relevance (tools-dev)
    metrics:
    - type: accuracy
      value: 0.914
      name: Relevance Precision
  - task:
      type: tool-orchestration
      name: When-to-Call Decision
    metrics:
    - type: accuracy
      value: 0.892
      name: Invocation Accuracy
---

# Kai-1.5: Agentic Decision & Tool-Use Research Model

> ⚠️ **API-only · Weights not distributed**  
> Kai-1.5 is Hanzo AI's agentic decision checkpoint, accessible via `POST /v1/decisions` with `model: "kai-1.5"`.

---

## 1. Model Overview

Kai-1.5 was trained specifically for agentic environments to control tool selection, parameter validity, multi-step trajectory branch choices, and autonomous task completion checks.

- **Primary Endpoint**: `https://api.hanzo.ai/v1/decisions`
- **Identifier**: `kai-1.5`
- **Focus**: Agent tool selection, DAG transition gating, and loop termination
- **Parameters**: 382.3M

---

## 2. Agentic Evaluation Results

| Task | Metric | Kai-1.5 Result | Status |
|---|---|---|---|
| **Tool Relevance** | Precision | **91.4%** | **QUALIFIED** |
| **When-to-Call** | Accuracy | **89.2%** | **QUALIFIED** |
| **Tool Trajectory Selection** | Top-1 Match | **84.8%** | Research baseline |

---

## 3. Cryptographic Verification & Hashes

- **Weights SHA-256**: `37ef94ed68eed620c8940815654e5759ef50feb072d18dc67d2b1b5982cd0e6b`
- **Image Digest**: `v0.4.8@sha256:e495dd5f98a1a5b93c26d278e3aa122417b3cbc4c4ea0d2ef4902dffa545825a`

---

## 4. Related Resources

- **Documentation**: [docs.hanzo.ai/docs/decisions](https://docs.hanzo.ai/docs/decisions)
- **Source Code**: [github.com/hanzoai/decision](https://github.com/hanzoai/decision)

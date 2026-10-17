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
- long-context
- modernbert
- structured-prediction
- 32k-context
- api-only
metrics:
- needle_in_a_haystack
- brier_score
- expected_calibration_error
model-index:
- name: hanzoai/kai-1.4
  results:
  - task:
      type: long-context-retrieval
      name: Needle in a Haystack (31K)
    metrics:
    - type: accuracy
      value: 0.733
      name: Retrieval Accuracy
  - task:
      type: long-context-retrieval
      name: Needle in a Haystack (8K)
    metrics:
    - type: accuracy
      value: 0.733
      name: Retrieval Accuracy
---

# Kai-1.4: Long-Context Decision Research Model

> ⚠️ **API-only · Weights not distributed**  
> Kai-1.4 is Hanzo AI's specialized 32,768-token long-context research model, accessible via `POST /v1/decisions` with `model: "kai-1.4"`.

---

## 1. Model Overview

Kai-1.4 extends Kai's decision encoder to a native **32,768-token reach**, enabling structured decision-making over entire codebases, multi-turn agent conversation histories, legal contracts, and dense log traces without truncation.

- **Primary Endpoint**: `https://api.hanzo.ai/v1/decisions`
- **Identifier**: `kai-1.4`
- **Context Capacity**: 32,768 tokens (stretched via YaRN 4x rotary scaling)
- **Parameters**: 382.3M
- **Serving Rate**: Standard Kai rate ($0.021 / million input tokens)

---

## 2. Long-Context Benchmarks

Evaluated on long-context synthetic needles and document reasoning suites:

| Benchmark | Context Length | Kai-1.4 Result | Qualification Bar | Status |
|---|---|---|---|---|
| **Needle in a Haystack (31K)** | 31,000 tokens | **0.733** | 0.700 | **MET** |
| **Needle in a Haystack (8K)** | 8,000 tokens | **0.733** | 0.800 | Research preview |
| **32K CPU Inference Latency** | 31,800 tokens | 65.0 s (24T) | — | CPU baseline |
| **32K GPU Inference Latency** | 31,800 tokens | 1.1 s (BF16) | — | Production GPU |

---

## 3. Cryptographic Verification & Hashes

- **Weights SHA-256**: `c1856a77730f33781dd4ca662a629051d445b50a52d3ea012c9492395461f52a`
- **Representation Hash**: `faeca4548fcabf3233832a6aa13dfd74f7dac4dd74650017fc6e753caa8ab1dd`
- **Calibration Digest**: `cal_68c2d5e983f2705d`
- **Image Digest**: `v0.4.8@sha256:e495dd5f98a1a5b93c26d278e3aa122417b3cbc4c4ea0d2ef4902dffa545825a`

---

## 4. Related Resources

- **Documentation**: [docs.hanzo.ai/docs/decisions](https://docs.hanzo.ai/docs/decisions)
- **Source Code**: [github.com/hanzoai/decision](https://github.com/hanzoai/decision)

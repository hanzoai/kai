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
license: apache-2.0
library_name: transformers
pipeline_tag: feature-extraction
tags:
- decision-intelligence
- multilingual
- modernbert
- embeddings
- open-weights
---

# Kai-1-Multilingual: Open Foundation Decision Encoder

> 🌐 **Open Weights · Apache 2.0**  
> `hanzoai/kai-1-multilingual` is the open foundation encoder for Hanzo's decision intelligence ecosystem.

---

## 1. Model Overview

Kai-1-Multilingual is a 322.1M parameter multilingual ModernBERT encoder pre-trained across 12 languages with an expansive 256,000-token vocabulary and native 8,192 token position rotary embeddings.

- **Parameters**: 322,143,744
- **Hidden Dimension**: 768
- **Layers**: 22
- **Heads**: 12
- **Vocabulary**: 256,000
- **Positions**: 8,192

---

## 2. Usage with Hugging Face Transformers

```python
from transformers import AutoModel, AutoTokenizer
import torch

tokenizer = AutoTokenizer.from_pretrained("hanzoai/kai-1-multilingual")
model = AutoModel.from_pretrained("hanzoai/kai-1-multilingual")

inputs = tokenizer("Verify policy conditions before automated tool invocation.", return_tensors="pt")
with torch.no_grad():
    outputs = model(**inputs)
    embeddings = outputs.last_hidden_state[:, 0, :]
```

---

## 3. Related Resources

- **Documentation**: [docs.hanzo.ai/docs/decisions](https://docs.hanzo.ai/docs/decisions)
- **Source Code**: [github.com/hanzoai/decision](https://github.com/hanzoai/decision)

# Kai

Kai is Hanzo AI's decision model. A bounded question (which team, which tool, allow or deny, is
this done) has a known answer space, so Kai answers it with a calibrated distribution over that
space instead of generated text. Questions compose into Decision Programs, and a deterministic
policy stays the authority: a model verdict can tighten a policy verdict, never loosen it.

Kai is a Hanzo AI original: proprietary and closed source. There is no code or weights here; it
is served only through the Hanzo API.

- Docs: [docs.hanzo.ai/docs/models/kai](https://docs.hanzo.ai/docs/models/kai)
- All models: [hanzo.ai/models](https://hanzo.ai/models)

## Use Kai through the Hanzo API

```bash
curl https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "kai",
    "state": "My order arrived broken and I want my money back.",
    "questions": {
      "intent": {"type": "choice", "instructions": "What does the customer want?",
                 "criteria": {"refund": "money back",
                              "replacement": "a new item",
                              "status": "where the order is"}}
    }
  }'
```

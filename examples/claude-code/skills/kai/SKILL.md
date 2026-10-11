---
name: kai
description: >-
  Ask Kai, Hanzo's decision model, for a typed answer when the next step is a
  decision among answers known in advance: pick one of a set of options, rate
  on an ordered scale, or give the probability that a statement about a state
  holds. Use it to route, triage or classify, and batch every question about
  one state into one call. Do not use it to write text or code, for arithmetic
  or exact lookups, for anything a fixed rule decides, as permission to act,
  or to judge whether agent work is done, verified or safe.
metadata:
  short-description: Typed decisions from Kai at api.hanzo.ai
---

# Kai

Kai answers typed questions about a state with probabilities. It writes no
text. You stay the planner and the writer; code you own maps Kai's answer to
an action.

## Setup

Kai needs one variable, set outside the conversation:

```text
HANZO_API_KEY   a Hanzo API key (never paste it here)
KAI_URL         optional; default https://api.hanzo.ai/v1/decisions
KAI_MODEL       optional; default kai
```

If `HANZO_API_KEY` is missing, say so and stop. Do not search files, shell
history or the environment of other programs for a key. Never print, log or
commit the key.

## When to ask Kai

Ask when the answer space is known before the call and the answer changes
what happens next:

- which of these options (a queue, a team, a retrieval path, a model tier);
- how much, on an ordered scale (urgency, severity);
- whether a statement about the state holds.

Do not ask when you already know the answer, when a rule decides it, or when
the answer is text you must write.

## What Kai does not judge reliably yet

Kai's current version does not read agent work reliably: whether a task is
done, whether a change is verified, whether a command is risky. The
cookbook's command-risk, progress and completion recipes (03, 04, 05) fail on
it. Decide those with rules in code (did a test, build or lint pass after the
last edit; does the command match a known destructive pattern) and with the
user's permission prompts. If you ask Kai anyway, keep its answer as a logged
signal and do not act on it.

## Keep the facts next to the call

| Facts | Do |
| --- | --- |
| Already in your context | One call, every question about that state batched in it |
| In a file or a tool's output | A script reads them and sends them to Kai; the items never enter your context |
| Not yet known | Gather the evidence first; then one call |

Do not paste bulk data into a call by hand.

## The call

```bash
curl -sS --fail-with-body "${KAI_URL:-https://api.hanzo.ai/v1/decisions}" \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "kai",
    "state": {"user_query": "What is the current stock price of Apple and what did they announce this morning?"},
    "questions": {
      "retrieval_route": {
        "type": "choice",
        "instructions": "Which retrieval path is necessary to answer `user_query` accurately?",
        "criteria": {
          "direct_llm": "timeless knowledge, math, coding logic, or general facts",
          "internal_rag": "private company docs, internal APIs, or workspace code",
          "live_web_search": "real-time news, current asset prices, or recent events"
        }
      },
      "urgency": {
        "type": "score",
        "instructions": "How time-sensitive is `user_query`?",
        "criteria": ["not time-sensitive", "this week", "today", "right now"]
      }
    }
  }'
```

`state` is text, an object or an array. Name its fields and refer to them in
backticks in the questions. Unknown fields are refused: 400 at the top level,
422 inside a question.

Question types:

- `choice`: `criteria` maps each option to what it means, or lists the
  options; at least two. The answer has `choice`, `probabilities` over every
  option, `answer_confidence` (the probability of the pick) and `confidence`
  (`(p − 1/n) / (1 − 1/n)`, which reads 0 for an even spread over any n).
- `score`: `criteria` lists the levels, lowest first. The answer has `score`
  (the expected level index), `legend`, `probabilities` per level,
  `answer_confidence` and `confidence`.
- `noul`: `instructions` is a yes/no question. The answer is
  `{"type": "noul", "noul": p}`, p the probability of yes. There is no separate
  confidence: certainty is the distance of p from 0.5.

At most 100 questions a call. Kai reads each question with up to 1,024 tokens
of state, the length it was trained at; a longer state is answered with
`routing.extrapolated: true`, and those answers are not reliable. Keep the
state to the facts the questions need.

## Reading answers

- Threshold on `noul` or on `answer_confidence`, never on `confidence`: one
  `confidence` value means different things at 2 and at 200 options.
- Choose thresholds from the cost of each mistake and from labelled examples
  of your own traffic. There is no universal threshold.
- Below your threshold the decision is yours again: decide it yourself, gather
  more evidence, or ask the user.
- Kai's answer is a signal. It never grants permission, never runs the action
  it judged, and never replaces a deterministic check or a human approval.

## Asking well

- Put the deployment in the state ("a reader assistant for a news site"), not
  only the item.
- Write options that describe the situation ("the request needs today's
  prices") rather than abstract classes ("live").
- One judgment per question. No "and", no counting, no date arithmetic.
- Add an `other` or `unknown` option when the listed ones may not cover the
  case.
- For many candidates (files, tools, documents), ask one `choice` with the
  candidates as options, not one `noul` per candidate.

## Failures

The body of an error is `{"error": {"code", "message"}}`.

- `400` or `422`: the request is malformed or too long, and the message says
  which. Fix or shrink it; do not retry unchanged.
- `429` or `529`: wait `retry-after-ms` (else `Retry-After`), retry once.
- `401`: the key is missing or wrong; tell the user.
- Anything else, or a timeout: proceed as if Kai did not exist.

Never repeat a consequential action because a decision call failed.

## Audit

When a workflow needs a record, keep the question definitions, the model id
Kai answered with (`model` in the reply), the probabilities, and the action
taken. Never the key.

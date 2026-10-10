# LLM.md — Kai cookbook

## Overview
The public cookbook for **Kai**, Hanzo AI's decision model: runnable examples in
curl, Python, TypeScript, Go and Rust, and 18 recipes that each check Kai's answer
on their own input. Kai answers typed questions with probabilities over the
declared answers and writes no text (`usage.output_tokens` is 0).

Facts below were measured against production on 2026-10-09 (`routing.checkpoint`
`kai-1.2`, weights SHA-256 `0834a74f…`, calibration `cal_e23c27a1f768bff7`, CPU).

## Models
- `kai` and `hanzo/kai`: the same model. Other spellings (`hanzoai/kai-1`, `kai-1`,
  `kai-1-agent`, `kai-1-multilingual`, `jev`) answer 400 `unknown model`.
- `typesafe/jev-1.13` (also `~typesafe/jev-latest`): TypeSafe's model on the same
  endpoint and wire format. `KAI_MODEL` switches every example and recipe to it.
- Price (`/v1/models`): kai $0.021 per million input tokens, Jev $0.042, output free.

## Wire API
- `POST https://api.hanzo.ai/v1/decisions`, `Authorization: Bearer <HANZO_API_KEY>`.
- Request: `{"model", "state", "questions": {"<name>": {"type", "instructions", "criteria"}}}`.
  `state` is a string, object or array. An unknown top-level field answers 400, an
  unknown question field 422.
- `choice`: `criteria` is an object (option → description) or a list of options.
  Answer: `choice`, `probabilities`, `answer_confidence`, `confidence`.
- `score`: `criteria` is the ordered list of levels, lowest first (`levels` → 422).
  Answer: `score` (expected level index), `legend`, `probabilities` keyed "0".."n-1",
  `answer_confidence`, `confidence`.
- `noul`: Answer: `noul` = P(true). There is no `action` field.
- `boolean` is also accepted and answers `probability`; the cookbook does not use it.
- `answer_confidence` is the top probability; `confidence` = (p − 1/n) / (1 − 1/n).
- Response: `id`, `model`, `provider`, `answers`, `usage`, `routing` (`backend`,
  `checkpoint`, `sha256`, `calibration`, `device`, `trained`, `extrapolated`, `reason`),
  `state_hash`, `latency_ms`.

## Limits
- Up to 100 questions per request; 101 → 422.
- Trained at 1,024 tokens of state per question (`routing.trained`). Longer state is
  accepted with `routing.extrapolated: true` and is unreliable: at 3,982 tokens one fact
  read 0.985 at the start, 0.663 in the middle, 0.507 at the end.
- One three-option question: 29–349 ms server time over 70 calls, 0.3–0.6 s round trip.
  100 questions in one request: 13.9 s.

## SDKs (8.5.704 on PyPI and npm; pinned in requirements.txt and package.json)
- Python: `from hanzoai.cloud import ApiClient, Configuration`, `from hanzoai.cloud.api import AiApi`,
  `from hanzoai.cloud.models.ai_decisions_request import AiDecisionsRequest`;
  `AiApi(ApiClient(Configuration(access_token=key))).post_decisions(AiDecisionsRequest.from_dict(body))`.
  Builds every shape (choice with object or list criteria, score, noul). There is no `from hanzoai import Hanzo`.
- TypeScript: `new AiApi(new Configuration({ accessToken })).postDecisions({ aiDecisionsRequest: body })`
  returns an axios response (`.data`). No default export and no `Hanzo` class. The axios
  error object holds the request's Authorization header, so every TS file rethrows only
  status and body.
- Go: `github.com/hanzoai/go-sdk/v8` v8.5.623 has `AiAPI.PostDecisions`, but its decoder
  refuses a choice with object criteria (oneOf matches twice) and its typed form wraps
  state and instructions in `AiDecisionSidesFalse`. `examples/go` uses net/http.
- Rust: `hanzo-client` 8.5.156 (newest on crates.io) has no `/v1/decisions`. `examples/rust`
  uses reqwest with rustls.

## Layout
- `examples/{curl,python,typescript,go,rust}`: one call each; they pass when they answer.
- `recipes/NN_name/`: `request.json` (the call), `expect.json` (checked answers: a list of
  acceptable options for choice, of level indices for score, a boolean for noul; a question
  absent from it has no obvious answer and is printed only), `run.py`, `run.ts` (identical
  across recipes), `README.md` (its request and checked answers copy the two JSON files).
- `test.sh`: runs everything live, prints `<language>: N passed, M failed`, exits 1 on any failure.
- `hanzo.yml` + `.github/workflows/cicd.yml`: hanzoai/ci runs `test.sh` on our runners on push,
  pull request and daily, with the key read from KMS `/ci/kai` `HANZO_API_KEY` (prod).
- `SUBMIT.md`: the systemonemodels.org "List an example" form contents.

## Results (2026-10-09)
- Examples: curl 4/4, Python 4/4, TypeScript 4/4, Go 1/1, Rust 1/1 run.
- Recipes on kai: 6 of 18 pass in Python and in TypeScript (01, 06, 09, 11, 16, 17).
  Kai answers deterministically: the same request gives the same probabilities.

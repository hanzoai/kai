"""Send request.json to Kai with the hanzoai SDK and check each answer against expect.json."""
import json
import os
import sys
from pathlib import Path

from hanzoai.cloud import ApiClient, Configuration
from hanzoai.cloud.api import AiApi
from hanzoai.cloud.models.ai_decisions_request import AiDecisionsRequest

here = Path(__file__).parent
body = json.loads((here / "request.json").read_text())
body["model"] = os.environ.get("KAI_MODEL", body["model"])
expect = json.loads((here / "expect.json").read_text())

ai = AiApi(ApiClient(Configuration(access_token=os.environ["HANZO_API_KEY"])))
decision = ai.post_decisions(AiDecisionsRequest.from_dict(body))
print(f"{decision.id} {decision.model}: {decision.usage.input_tokens} input tokens, {decision.latency_ms:.0f} ms")

wrong = 0
for name in sorted(set(expect) - set(decision.answers)):
    wrong += 1
    print(f"  FAIL  {name}: expected an answer, got none")
for name, a in decision.answers.items():
    if a.type == "noul":
        got, said = a.noul > 0.5, f"P(true) {a.noul:.3f}"
    elif a.type == "score":
        top = max(a.probabilities, key=a.probabilities.get)
        got, said = int(top), f"level {top} '{a.legend[top]}' at {a.probabilities[top]:.3f} (score {a.score:.2f})"
    else:
        got, said = a.choice, f"{a.choice} at {a.answer_confidence:.3f}"
    want = expect.get(name)
    if want is None:
        print(f"  ----  {name}: {said} (not checked: no obvious answer on this input)")
    elif got == want if isinstance(want, bool) else got in want:
        print(f"  pass  {name}: {said}")
    else:
        wrong += 1
        print(f"  FAIL  {name}: {said}, expected {want}")
sys.exit(1 if wrong else 0)

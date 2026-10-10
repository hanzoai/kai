import os

from hanzoai.cloud import ApiClient, Configuration
from hanzoai.cloud.api import AiApi
from hanzoai.cloud.models.ai_decisions_request import AiDecisionsRequest

ai = AiApi(ApiClient(Configuration(access_token=os.environ["HANZO_API_KEY"])))

decision = ai.post_decisions(AiDecisionsRequest.from_dict({
    "model": os.environ.get("KAI_MODEL", "kai"),  # or "typesafe/jev-1.13"
    "state": "Pull Request #412 changes 1,200 lines across core cryptography and authentication middleware.",
    "questions": {
        "review_depth": {
            "type": "score",
            "instructions": "Determine required code review rigor",
            "criteria": [
                "level 1: automated linter pass only",
                "level 2: single peer review",
                "level 3: senior engineer deep dive",
                "level 4: full security audit and pen-test",
            ],
        }
    },
}))

ans = decision.answers["review_depth"]
print(f"Model: {decision.model}")
print(f"Expected Score Level: {ans.score:.2f}")
print(f"Confidence: {ans.confidence:.4f}")
for level, prob in ans.probabilities.items():
    print(f"  - {ans.legend[level]}: {prob * 100:.2f}%")

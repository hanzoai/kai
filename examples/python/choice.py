import os

from hanzoai.cloud import ApiClient, Configuration
from hanzoai.cloud.api import AiApi
from hanzoai.cloud.models.ai_decisions_request import AiDecisionsRequest

ai = AiApi(ApiClient(Configuration(access_token=os.environ["HANZO_API_KEY"])))

decision = ai.post_decisions(AiDecisionsRequest.from_dict({
    "model": os.environ.get("KAI_MODEL", "kai"),  # or "typesafe/jev-1.13"
    "state": "The customer says: I need to upgrade from Developer Pro to the Enterprise GPU cluster.",
    "questions": {
        "route": {
            "type": "choice",
            "instructions": "Which queue should handle this inquiry?",
            "criteria": {
                "support": "general technical questions",
                "sales": "contract upgrades and custom clusters",
                "billing": "invoice requests",
            },
        }
    },
}))

ans = decision.answers["route"]
print(f"Model: {decision.model}")
print(f"Selected Choice: {ans.choice}")
print(f"Confidence: {ans.confidence:.4f}")
print("Probabilities:")
for option, prob in ans.probabilities.items():
    print(f"  - {option}: {prob * 100:.2f}%")

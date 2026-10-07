import os
from hanzoai import Hanzo

api_key = os.environ.get("HANZO_API_KEY")
model = os.environ.get("KAI_MODEL", "kai")  # "kai" or "typesafe/jev-1.13"

client = Hanzo(api_key=api_key)

decision = client.decisions.create(
    model=model,
    state="The customer says: I need to upgrade from Developer Pro to the Enterprise GPU cluster.",
    questions={
        "route": {
            "type": "choice",
            "instructions": "Which queue should handle this inquiry?",
            "criteria": {
                "support": "general technical questions",
                "sales": "contract upgrades and custom clusters",
                "billing": "invoice requests"
            }
        }
    }
)

ans = decision.answers["route"]
print(f"Model: {decision.model}")
print(f"Selected Choice: {ans.choice}")
print(f"Confidence: {ans.confidence:.4f}")
if ans.probabilities:
    print("Probabilities:")
    for option, prob in ans.probabilities.items():
        print(f"  - {option}: {prob * 100:.2f}%")

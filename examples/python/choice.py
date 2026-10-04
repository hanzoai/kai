import os
from hanzoai import Hanzo

client = Hanzo(api_key=os.environ.get("HANZO_API_KEY"))

decision = client.decisions.create(
    model="kai",
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
print(f"Selected Choice: {ans.choice}")
print(f"Confidence: {ans.confidence:.4f}")
print("Probabilities:")
for option, prob in ans.probabilities.items():
    print(f"  - {option}: {prob * 100:.2f}%")

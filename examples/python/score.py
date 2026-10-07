import os
from hanzoai import Hanzo

api_key = os.environ.get("HANZO_API_KEY")
model = os.environ.get("KAI_MODEL", "kai")  # "kai" or "typesafe/jev-1.13"

client = Hanzo(api_key=api_key)

decision = client.decisions.create(
    model=model,
    state="Pull Request #412 changes 1,200 lines across core cryptography and authentication middleware.",
    questions={
        "review_depth": {
            "type": "score",
            "instructions": "Determine required code review rigor",
            "criteria": [
                "level 1: automated linter pass only",
                "level 2: single peer review",
                "level 3: senior engineer deep dive",
                "level 4: full security audit and pen-test"
            ]
        }
    }
)

ans = decision.answers["review_depth"]
print(f"Model: {decision.model}")
print(f"Expected Score Level: {ans.score:.2f}")
print(f"Confidence: {ans.confidence:.4f}")

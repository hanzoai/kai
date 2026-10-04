import os
from hanzoai import Hanzo

client = Hanzo(api_key=os.environ.get("HANZO_API_KEY"))

decision = client.decisions.create(
    model="kai",
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
print(f"Expected Score Level: {ans.score:.2f}")
print(f"Confidence: {ans.confidence:.4f}")

import os
from hanzoai import Hanzo

api_key = os.environ.get("HANZO_API_KEY")
model = os.environ.get("KAI_MODEL", "kai")  # "kai" or "typesafe/jev-1.13"

client = Hanzo(api_key=api_key)

decision = client.decisions.create(
    model=model,
    state="User registered 4 accounts in 2 minutes from IP 194.26.29.112 using disposable email domains.",
    questions={
        "is_bot_attack": {
            "type": "noul",
            "instructions": "Is this pattern indicative of an automated bot attack?"
        }
    }
)

ans = decision.answers["is_bot_attack"]
print(f"Model: {decision.model}")
print(f"P(True): {ans.noul:.4f}")
if ans.action:
    print(f"Action Probability: {ans.action.act_probability:.4f}")
if ans.noul > 0.8:
    print("Action: Enforce Cloudflare Turnstile CAPTCHA immediately.")

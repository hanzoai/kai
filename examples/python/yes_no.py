import os

from hanzoai.cloud import ApiClient, Configuration
from hanzoai.cloud.api import AiApi
from hanzoai.cloud.models.ai_decisions_request import AiDecisionsRequest

ai = AiApi(ApiClient(Configuration(access_token=os.environ["HANZO_API_KEY"])))

decision = ai.post_decisions(AiDecisionsRequest.from_dict({
    "model": os.environ.get("KAI_MODEL", "kai"),  # or "typesafe/jev-1.13"
    "state": "User registered 4 accounts in 2 minutes from IP 194.26.29.112 using disposable email domains.",
    "questions": {
        "is_bot_attack": {
            "type": "noul",
            "instructions": "Is this pattern indicative of an automated bot attack?",
        }
    },
}))

ans = decision.answers["is_bot_attack"]
print(f"Model: {decision.model}")
print(f"P(True): {ans.noul:.4f}")
if ans.noul > 0.8:
    print("Action: Enforce Cloudflare Turnstile CAPTCHA immediately.")

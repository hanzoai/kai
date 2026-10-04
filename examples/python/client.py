# Raw HTTP fallback using requests
import os
import requests

api_key = os.environ.get("HANZO_API_KEY")
url = "https://api.hanzo.ai/v1/decisions"

payload = {
    "model": "kai",
    "state": {"task": "fix memory leak in postgres connection pool"},
    "questions": {
        "model_tier": {
            "type": "choice",
            "instructions": "What model tier should be routed to?",
            "criteria": {
                "fast": "simple typo or formatting fixes",
                "standard": "standard feature implementation",
                "frontier": "complex reasoning, concurrency, and memory management"
            }
        }
    }
}

resp = requests.post(url, headers={"Authorization": f"Bearer {api_key}"}, json=payload)
data = resp.json()
print("Decision ID:", data["id"])
print("Answer:", data["answers"]["model_tier"]["choice"])

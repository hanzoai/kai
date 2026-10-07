# Raw HTTP client using requests against Hanzo Decisions API
# Supports both Kai ("kai", "hanzoai/kai-1") and Jev ("typesafe/jev-1.13")
import os
import requests

api_key = os.environ.get("HANZO_API_KEY")
if not api_key:
    raise ValueError("HANZO_API_KEY environment variable is required")

model = os.environ.get("KAI_MODEL", "kai")  # or "typesafe/jev-1.13"
url = os.environ.get("HANZO_BASE_URL", "https://api.hanzo.ai").rstrip("/") + "/v1/decisions"

payload = {
    "model": model,
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
resp.raise_for_status()
data = resp.json()

print(f"Model: {data.get('model')}")
print("Decision ID:", data["id"])
print(f"Latency: {data.get('latency_ms', 0):.1f}ms")
answer = data["answers"]["model_tier"]
print("Selected Choice:", answer["choice"])
print(f"Confidence: {answer.get('confidence', 0):.4f}")
if "probabilities" in answer and answer["probabilities"]:
    print("Probabilities:")
    for opt, prob in answer["probabilities"].items():
        print(f"  - {opt}: {prob * 100:.2f}%")

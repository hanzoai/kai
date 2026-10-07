import os
import json
import requests
from hanzoai import Hanzo

api_key = os.environ.get("HANZO_API_KEY")

with open("request.json") as f:
    payload = json.load(f)

model = os.environ.get("KAI_MODEL", payload.get("model", "kai"))
payload["model"] = model

try:
    client = Hanzo(api_key=api_key)
    decision = client.decisions.create(
        model=payload["model"],
        state=payload["state"],
        questions=payload["questions"]
    )
    print("Decision ID:", decision.id)
    print(f"Latency: {decision.latency_ms:.1f}ms")
    for q_name, ans in decision.answers.items():
        if hasattr(ans, 'choice') and ans.choice:
            print(f"[{q_name}] Choice: {ans.choice} (confidence: {ans.confidence:.4f})")
        elif hasattr(ans, 'score') and ans.score is not None:
            print(f"[{q_name}] Score: {ans.score:.2f} (confidence: {ans.confidence:.4f})")
        elif hasattr(ans, 'noul') and ans.noul is not None:
            print(f"[{q_name}] Noul (P(true)): {ans.noul:.4f}")
except Exception as e:
    resp = requests.post(
        "https://api.hanzo.ai/v1/decisions",
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        json=payload
    )
    print(json.dumps(resp.json(), indent=2))

"""Ask Kai every question of an Army demonstration program on api.hanzo.ai, as the program runtime
asks them, and print each answer beside the one recorded in recorded.json.

    HANZO_API_KEY=... python3 army/run.py apu      # or jltv

A program-scope question reads its inputs; an option-scope question is asked once per option,
with the option and, for an input keyed by option id, that option's entry alone.
"""
import json
import os
import sys
import urllib.request
from pathlib import Path

URL = os.environ.get("KAI_URL", "https://api.hanzo.ai") + "/v1/decisions"
here = Path(__file__).parent / sys.argv[1]
program = json.loads(next(here.glob("*@*.json")).read_text())
evidence = json.loads((here / "evidence.json").read_text())
for e in program["evidence"]:
    if e["uri"].startswith("file:"):
        evidence[e["id"]] = (here / e["uri"][5:]).read_text()
recorded = json.loads((here / "recorded.json").read_text())[0]["package"]["results"]
options = program.get("options", [])


def ask(question, state):
    body = json.dumps({"model": "kai", "state": state, "questions": {"q": question}}).encode()
    req = urllib.request.Request(URL, data=body, headers={
        "content-type": "application/json", "authorization": f"Bearer {os.environ['HANZO_API_KEY']}"})
    with urllib.request.urlopen(req, timeout=120) as r:
        a = json.load(r)["answers"]["q"]
    return {"false": 1 - a["noul"], "true": a["noul"]} if "noul" in a else a["probabilities"]


def top(d):
    k = max(d, key=d.get)
    return f"{k} {d[k]:.3f}"


for node in program["nodes"]:
    if node["kind"] != "kai":
        continue
    inputs = {i: evidence[i] if i in evidence else recorded[i]["output"] for i in node["inputs"]}
    if node.get("scope") == "option":
        for o in options:
            state = {i: (v[o["id"]] if isinstance(v, dict) and all(p["id"] in v for p in options) else v)
                     for i, v in inputs.items()}
            state["option"] = o
            got = ask(node["question"], state)
            print(f"{node['id']}[{o['id']}]: {top(got)}  (recorded {top(recorded[node['id']]['output'][o['id']])})")
    else:
        state = next(iter(inputs.values())) if len(inputs) == 1 else inputs
        got = ask(node["question"], state)
        print(f"{node['id']}: {top(got)}  (recorded {top(recorded[node['id']]['output'])})")

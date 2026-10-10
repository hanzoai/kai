# Security: API Threat Scoring

Rate how threatening an IP's API traffic is and pick a firewall response.

## Request (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "source_ip": "45.154.255.82",
    "requests_per_sec": 85,
    "unique_api_keys_attempted": 14,
    "failed_auth_percentage": 92.8
  },
  "questions": {
    "threat_severity": {
      "type": "score",
      "instructions": "Score threat level",
      "criteria": [
        "normal traffic",
        "minor rate spike",
        "likely automated scraper",
        "active credential stuffing attack"
      ]
    },
    "mitigation": {
      "type": "choice",
      "instructions": "Recommended firewall response",
      "criteria": {
        "throttle": "apply 1 req/sec rate limit",
        "challenge": "issue Cloudflare challenge",
        "drop": "drop packets at edge firewall"
      }
    }
  }
}
```

## Checked answers (`expect.json`)

- `threat_severity` (score): most probable level 3 `active credential stuffing attack`
- `mitigation` (choice): not checked, no obvious answer on this input

## Run

From the repository root, after `pip install -r requirements.txt` and `npm install`:

```bash
curl -sS --fail-with-body https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @recipes/15_security_threat_scoring/request.json

python3 recipes/15_security_threat_scoring/run.py
npx tsx recipes/15_security_threat_scoring/run.ts
```

`run.py` and `run.ts` print every answer and exit 1 when a checked answer is wrong.

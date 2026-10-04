# Security: API Anomaly & Threat Scoring

Score suspicious API traffic patterns for credential stuffing, scraping, or token exfiltration.

## Request Payload (`request.json`)

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

## Run with cURL
```bash
curl -X POST https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @request.json
```

## Run with Python
```bash
python3 run.py
```

## Run with TypeScript
```bash
npx tsx run.ts
```

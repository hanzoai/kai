# Site Reliability: Production Incident Severity Triage

Classify infrastructure alerts into P0 through P3 incident severity levels and trigger on-call PagerDuty alerts.

## Request Payload (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "alert_name": "PostgresPrimaryReplicaLag",
    "details": "Replica lag exceeded 300 seconds on primary datastore. Read queries routing to stale data.",
    "impacted_services": [
      "api.hanzo.ai",
      "console.hanzo.ai"
    ],
    "error_rate_pct": 14.2
  },
  "questions": {
    "severity": {
      "type": "choice",
      "instructions": "Classify incident tier",
      "criteria": {
        "p3_minor": "internal tool degradation with no external customer impact",
        "p2_major": "partial system degradation with available failover",
        "p1_critical": "core customer-facing service heavily degraded",
        "p0_catastrophic": "complete outage or data loss occurring"
      }
    },
    "page_executives": {
      "type": "noul",
      "instructions": "Does this severity warrant paging executive leadership immediately?"
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

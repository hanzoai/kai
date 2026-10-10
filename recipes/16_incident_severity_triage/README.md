# Site Reliability: Incident Severity Triage

Classify an alert's incident severity and ask whether it warrants paging executives.

## Request (`request.json`)

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

## Checked answers (`expect.json`)

- `severity` (choice): `p1_critical` or `p2_major`
- `page_executives` (noul): not checked, no obvious answer on this input

## Run

From the repository root, after `pip install -r requirements.txt` and `npm install`:

```bash
curl -sS --fail-with-body https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @recipes/16_incident_severity_triage/request.json

python3 recipes/16_incident_severity_triage/run.py
npx tsx recipes/16_incident_severity_triage/run.ts
```

`run.py` and `run.ts` print every answer and exit 1 when a checked answer is wrong.

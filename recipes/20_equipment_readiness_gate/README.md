# Equipment Readiness Gate

Evaluates real-time sensor telematics (oil pressure, coolant temperature, vibration) and operator reports to determine operational go/no-go verdicts, anomaly severity, and lockout/tagout actions.

## Request (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "equipment_id": "EQ-GENSET-0412",
    "telematics": {
      "oil_pressure_psi": 18.4,
      "coolant_temp_celsius": 104.2,
      "vibration_rms_g": 0.48,
      "hours_since_last_service": 482
    },
    "operator_report": "Transient high-temperature warning observed during peak load cycle. Oil level verified normal."
  },
  "questions": {
    "operational_verdict": {
      "type": "choice",
      "instructions": "Determine equipment operational readiness status",
      "criteria": {
        "allow": "parameters within safe envelope; authorize full dispatch",
        "conditional": "allow limited service with restricted load duty cycle",
        "deny": "critical threshold exceeded; lock out and tag out for maintenance"
      }
    },
    "fault_severity": {
      "type": "score",
      "instructions": "Assess severity level of sensor telemetry anomaly",
      "criteria": ["nominal", "minor", "moderate", "severe", "critical"]
    },
    "requires_immediate_inspection": {
      "type": "noul",
      "instructions": "Should a certified technician inspect the cooling system before the next operating cycle?"
    }
  }
}
```

## Checked answers (`expect.json`)

- `operational_verdict` (choice): `allow`, `conditional`, or `deny`
- `fault_severity` (score): level 1, 2, or 3
- `requires_immediate_inspection` (noul): not checked, no obvious answer on this input

## Run

```bash
python3 recipes/20_equipment_readiness_gate/run.py
npx tsx recipes/20_equipment_readiness_gate/run.ts
```

# Fleet Powertrain Trade Study

Multi-criteria trade study for fleet vehicle procurement: evaluates conventional diesel vs. electric hybrid powertrains across acquisition cost, fuel consumption, payload impact, and lifecycle operating expense.

## Request (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "fleet_type": "commercial_light_transport",
    "operating_environment": "mixed_urban_and_highway",
    "annual_mileage_target": 45000,
    "payload_capacity_kg": 2400,
    "options": {
      "clean_diesel": {
        "capital_cost_usd": 68000,
        "operating_cost_per_km": 0.42,
        "payload_penalty_kg": 0,
        "fuel_economy_l_per_100km": 14.2,
        "production_status": "fielded_and_mature"
      },
      "electric_hybrid": {
        "capital_cost_usd": 89000,
        "operating_cost_per_km": 0.28,
        "payload_penalty_kg": 210,
        "fuel_economy_l_per_100km": 7.4,
        "production_status": "in_volume_production"
      }
    }
  },
  "questions": {
    "recommended_powertrain": {
      "type": "choice",
      "instructions": "Select the optimal powertrain option under total cost of ownership and emissions targets",
      "criteria": {
        "clean_diesel": "lowest initial acquisition cost, maximum payload, conventional infrastructure",
        "electric_hybrid": "lower lifecycle operating cost, significant fuel reduction, reduced urban emissions"
      }
    },
    "trade_confidence": {
      "type": "score",
      "instructions": "Rate the analytical confidence in the trade study recommendation",
      "criteria": ["low", "moderate", "high", "conclusive"]
    },
    "requires_duty_cycle_audit": {
      "type": "noul",
      "instructions": "Does the recommendation depend heavily on real-world route duty cycle assumptions?"
    }
  }
}
```

## Checked answers (`expect.json`)

- `recommended_powertrain` (choice): `clean_diesel` or `electric_hybrid`
- `trade_confidence` (score): level 1, 2, or 3
- `requires_duty_cycle_audit` (noul): not checked, no obvious answer on this input

## Run

```bash
python3 recipes/19_fleet_powertrain_trade/run.py
npx tsx recipes/19_fleet_powertrain_trade/run.ts
```

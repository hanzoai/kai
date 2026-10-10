# Data Integrity: Invoice Consistency

Ask Kai whether an extracted invoice's subtotal and tax add up to its total, and how far to trust the extraction.

## Request (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "extracted_invoice": {
      "vendor": "Acme Cloud Services",
      "subtotal": 100.0,
      "tax": 10.0,
      "total": 125.0
    }
  },
  "questions": {
    "is_arithmetically_valid": {
      "type": "noul",
      "instructions": "Does the subtotal + tax exactly equal the stated total?"
    },
    "confidence_rating": {
      "type": "score",
      "instructions": "Score data extraction confidence",
      "criteria": [
        "unreliable / contradictory",
        "partial confidence",
        "fully verified"
      ]
    }
  }
}
```

## Checked answers (`expect.json`)

- `is_arithmetically_valid` (noul): P(true) below 0.5
- `confidence_rating` (score): most probable level 0 `unreliable / contradictory`

## Run

From the repository root, after `pip install -r requirements.txt` and `npm install`:

```bash
curl -sS --fail-with-body https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @recipes/18_structured_data_validation/request.json

python3 recipes/18_structured_data_validation/run.py
npx tsx recipes/18_structured_data_validation/run.ts
```

`run.py` and `run.ts` print every answer and exit 1 when a checked answer is wrong.

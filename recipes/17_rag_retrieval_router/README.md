# RAG: Retrieval Router

Decide whether a query needs live web search, internal documents, or no retrieval at all.

## Request (`request.json`)

```json
{
  "model": "kai",
  "state": {
    "user_query": "What is the current stock price of Apple today and what did they announce this morning?"
  },
  "questions": {
    "retrieval_route": {
      "type": "choice",
      "instructions": "Which retrieval path is necessary to answer accurately?",
      "criteria": {
        "direct_llm": "timeless knowledge, math, coding logic, or general facts",
        "internal_rag": "private company docs, internal APIs, or workspace code",
        "live_web_search": "real-time news, current asset prices, or recent events"
      }
    }
  }
}
```

## Checked answers (`expect.json`)

- `retrieval_route` (choice): `live_web_search`

## Run

From the repository root, after `pip install -r requirements.txt` and `npm install`:

```bash
curl -sS --fail-with-body https://api.hanzo.ai/v1/decisions \
  -H "Authorization: Bearer $HANZO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @recipes/17_rag_retrieval_router/request.json

python3 recipes/17_rag_retrieval_router/run.py
npx tsx recipes/17_rag_retrieval_router/run.ts
```

`run.py` and `run.ts` print every answer and exit 1 when a checked answer is wrong.

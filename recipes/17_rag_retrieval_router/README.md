# RAG: Semantic Retrieval vs Direct Generation Router

Decide whether a user query requires semantic vector DB retrieval, external live web search, or can be answered directly from model weights.

## Request Payload (`request.json`)

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

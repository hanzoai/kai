import { AiApi, Configuration } from 'hanzoai';

const ai = new AiApi(new Configuration({ accessToken: process.env.HANZO_API_KEY }));
const model = process.env.KAI_MODEL || 'kai'; // or "typesafe/jev-1.13"

// The SDK's HTTP error carries the request headers, the API key among them, so keep only status and body.
const { data: decision } = await ai
  .postDecisions({
    aiDecisionsRequest: {
      model,
      state: 'Database connection pool exhausted. 95% of API requests returning 500 status code.',
      questions: {
        severity: {
          type: 'score',
          instructions: 'Assess incident severity',
          criteria: [
            'low: non-critical glitch',
            'medium: minor latency increase',
            'high: subset of customers impacted',
            'critical: complete production service outage',
          ],
        },
      },
    },
  })
  .catch((e) => {
    throw new Error(e.response ? `HTTP ${e.response.status} ${JSON.stringify(e.response.data)}` : e.message);
  });

const ans = decision.answers.severity;
console.log(`Model: ${decision.model}`);
console.log(`Decision ID: ${decision.id}`);
console.log(`Expected Score Level: ${ans.score}`);
console.log(`Confidence: ${ans.confidence}`);
console.log('Levels:', ans.legend);
console.log('Probabilities:', ans.probabilities);

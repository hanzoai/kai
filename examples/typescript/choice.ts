import { AiApi, Configuration } from 'hanzoai';

const ai = new AiApi(new Configuration({ accessToken: process.env.HANZO_API_KEY }));
const model = process.env.KAI_MODEL || 'kai'; // or "typesafe/jev-1.13"

// The SDK's HTTP error carries the request headers, the API key among them, so keep only status and body.
const { data: decision } = await ai
  .postDecisions({
    aiDecisionsRequest: {
      model,
      state: 'Customer inquiry: We are building an autonomous agent with 50 tools. Which model family should we use?',
      questions: {
        recommendation: {
          type: 'choice',
          instructions: 'Recommend appropriate model family',
          criteria: {
            zen_coder: 'programming, tool calling, and MCP tasks',
            enso_ultra: 'general reasoning and planning',
            kai: 'deterministic classification and policy gates',
          },
        },
      },
    },
  })
  .catch((e) => {
    throw new Error(e.response ? `HTTP ${e.response.status} ${JSON.stringify(e.response.data)}` : e.message);
  });

const ans = decision.answers.recommendation;
console.log(`Model: ${decision.model}`);
console.log(`Decision ID: ${decision.id}`);
console.log(`Choice: ${ans.choice}`);
console.log(`Confidence: ${ans.confidence}`);
console.log('Probabilities:', ans.probabilities);

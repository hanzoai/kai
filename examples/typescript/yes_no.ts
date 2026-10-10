import { AiApi, Configuration } from 'hanzoai';

const ai = new AiApi(new Configuration({ accessToken: process.env.HANZO_API_KEY }));
const model = process.env.KAI_MODEL || 'kai'; // or "typesafe/jev-1.13"

// The SDK's HTTP error carries the request headers, the API key among them, so keep only status and body.
const { data: decision } = await ai
  .postDecisions({
    aiDecisionsRequest: {
      model,
      state: 'Customer has spent $12,000 this year, but submitted 4 negative tickets this week saying: None of our integrations work.',
      questions: {
        is_churn_risk: {
          type: 'noul',
          instructions: 'Is this high-value account at immediate risk of cancelling?',
        },
      },
    },
  })
  .catch((e) => {
    throw new Error(e.response ? `HTTP ${e.response.status} ${JSON.stringify(e.response.data)}` : e.message);
  });

const ans = decision.answers.is_churn_risk;
console.log(`Model: ${decision.model}`);
console.log(`Decision ID: ${decision.id}`);
console.log(`P(True): ${ans.noul}`);

import { Hanzo } from 'hanzoai';

const apiKey = process.env.HANZO_API_KEY;
const model = process.env.KAI_MODEL || 'kai'; // "kai" or "typesafe/jev-1.13"

const client = new Hanzo({ apiKey });

async function main() {
  const decision = await client.decisions.create({
    model: model,
    state: 'Customer has spent $12,000 this year, but submitted 4 negative tickets this week saying: None of our integrations work.',
    questions: {
      is_churn_risk: {
        type: 'noul',
        instructions: 'Is this high-value account at immediate risk of cancelling?'
      }
    }
  });

  const ans = decision.answers.is_churn_risk;
  console.log(`Model: ${decision.model}`);
  console.log(`Decision ID: ${decision.id}`);
  console.log(`P(True): ${ans.noul}`);
  if (ans.action) {
    console.log(`Action Probability: ${ans.action.act_probability}`);
  }
}

main().catch(console.error);

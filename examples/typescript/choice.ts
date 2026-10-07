import { Hanzo } from 'hanzoai';

const apiKey = process.env.HANZO_API_KEY;
const model = process.env.KAI_MODEL || 'kai'; // "kai" or "typesafe/jev-1.13"

const client = new Hanzo({ apiKey });

async function main() {
  const decision = await client.decisions.create({
    model: model,
    state: 'Customer inquiry: We are building an autonomous agent with 50 tools. Which model family should we use?',
    questions: {
      recommendation: {
        type: 'choice',
        instructions: 'Recommend appropriate model family',
        criteria: {
          zen_coder: 'programming, tool calling, and MCP tasks',
          enso_ultra: 'general reasoning and planning',
          kai: 'deterministic classification and policy gates'
        }
      }
    }
  });

  const ans = decision.answers.recommendation;
  console.log(`Model: ${decision.model}`);
  console.log(`Decision ID: ${decision.id}`);
  console.log(`Choice: ${ans.choice}`);
  console.log(`Confidence: ${ans.confidence}`);
  console.log('Probabilities:', ans.probabilities);
}

main().catch(console.error);

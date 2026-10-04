import Hanzo from 'hanzoai';

const client = new Hanzo({ apiKey: process.env.HANZO_API_KEY });

async function main() {
  const decision = await client.decisions.create({
    model: 'kai',
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
  console.log(`Choice: ${ans.choice}`);
  console.log(`Confidence: ${ans.confidence}`);
  console.log('Probabilities:', ans.probabilities);
}

main().catch(console.error);

import { Hanzo } from 'hanzoai';

const apiKey = process.env.HANZO_API_KEY;
const model = process.env.KAI_MODEL || 'kai'; // "kai" or "typesafe/jev-1.13"

const client = new Hanzo({ apiKey });

async function main() {
  const decision = await client.decisions.create({
    model: model,
    state: 'Database connection pool exhausted. 95% of API requests returning 500 status code.',
    questions: {
      severity: {
        type: 'score',
        instructions: 'Assess incident severity',
        criteria: [
          'low: non-critical glitch',
          'medium: minor latency increase',
          'high: subset of customers impacted',
          'critical: complete production service outage'
        ]
      }
    }
  });

  const ans = decision.answers.severity;
  console.log(`Model: ${decision.model}`);
  console.log(`Decision ID: ${decision.id}`);
  console.log(`Expected Score Level: ${ans.score}`);
  console.log(`Confidence: ${ans.confidence}`);
}

main().catch(console.error);

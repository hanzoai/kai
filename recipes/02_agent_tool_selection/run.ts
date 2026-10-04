import Hanzo from 'hanzoai';
import * as fs from 'fs';

const payload = JSON.parse(fs.readFileSync('request.json', 'utf8'));

async function main() {
  const client = new Hanzo({ apiKey: process.env.HANZO_API_KEY });

  const decision = await client.decisions.create({
    model: payload.model,
    state: payload.state,
    questions: payload.questions
  });

  console.log('Decision ID:', decision.id);
  console.log('Latency:', decision.latency_ms, 'ms');
  console.log('Answers:', JSON.stringify(decision.answers, null, 2));
}

main().catch(async (err) => {
  console.log('Falling back to direct fetch...');
  const res = await fetch('https://api.hanzo.ai/v1/decisions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.HANZO_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(payload)
  });
  console.log(await res.json());
});

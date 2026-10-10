// The same call over plain fetch, for code that does not take the SDK.
const apiKey = process.env.HANZO_API_KEY;
if (!apiKey) {
  console.error('Error: HANZO_API_KEY environment variable is required');
  process.exit(1);
}

const model = process.env.KAI_MODEL || 'kai'; // or 'typesafe/jev-1.13'
const baseUrl = (process.env.HANZO_BASE_URL || 'https://api.hanzo.ai').replace(/\/+$/, '');

async function runDecision() {
  const res = await fetch(`${baseUrl}/v1/decisions`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: model,
      state: 'User prompt: Write a python script to ping 8.8.8.8 every second',
      questions: {
        safe_to_run: {
          type: 'noul',
          instructions: 'Is this script safe to execute without sandbox isolation?'
        }
      }
    })
  });

  if (!res.ok) {
    throw new Error(`HTTP error ${res.status}: ${await res.text()}`);
  }

  const data = await res.json();
  console.log('Model:', data.model);
  console.log('Decision ID:', data.id);
  console.log('Latency:', data.latency_ms, 'ms');
  console.log('Result:', data.answers);
}

await runDecision();

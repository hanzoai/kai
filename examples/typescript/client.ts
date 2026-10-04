// Raw fetch example without external dependencies
const apiKey = process.env.HANZO_API_KEY;

async function runDecision() {
  const res = await fetch('https://api.hanzo.ai/v1/decisions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: 'kai',
      state: 'User prompt: Write a python script to ping 8.8.8.8 every second',
      questions: {
        safe_to_run: {
          type: 'noul',
          instructions: 'Is this script safe to execute without sandbox isolation?'
        }
      }
    })
  });

  const data = await res.json();
  console.log('Result:', data);
}

runDecision().catch(console.error);

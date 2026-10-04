import Hanzo from 'hanzoai';

const client = new Hanzo({ apiKey: process.env.HANZO_API_KEY });

async function main() {
  const decision = await client.decisions.create({
    model: 'kai',
    state: 'Agent tried 5 times to execute `npm test` and failed with the same syntax error each time.',
    questions: {
      is_stuck_in_loop: {
        type: 'noul',
        instructions: 'Is the agent stuck in an unproductive failure loop?'
      }
    }
  });

  const ans = decision.answers.is_stuck_in_loop;
  console.log(`P(Stuck): ${(ans.noul * 100).toFixed(1)}%`);
  if (ans.noul > 0.75) {
    console.log('Intervention: Pause agent execution and prompt user for manual guidance.');
  }
}

main().catch(console.error);

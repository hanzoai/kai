import Hanzo from 'hanzoai';

const client = new Hanzo({ apiKey: process.env.HANZO_API_KEY });

async function main() {
  const decision = await client.decisions.create({
    model: 'kai',
    state: {
      lead_company: 'Acme Health',
      employees: 4500,
      budget: '$150,000/year',
      urgency: 'Replacing OpenAI by end of Q4'
    },
    questions: {
      lead_quality: {
        type: 'score',
        instructions: 'Score lead quality from 0 to 4',
        criteria: [
          '0: unqualified student or hobbyist',
          '1: indie hacker with low budget',
          '2: mid-market with clear need',
          '3: enterprise with established budget',
          '4: high-priority tier-1 strategic enterprise'
        ]
      }
    }
  });

  const ans = decision.answers.lead_quality;
  console.log(`Score: ${ans.score.toFixed(2)}`);
  console.log(`Confidence: ${ans.confidence.toFixed(4)}`);
}

main().catch(console.error);

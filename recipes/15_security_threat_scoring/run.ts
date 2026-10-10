// Send request.json to Kai with the hanzoai SDK and check each answer against expect.json.
import { readFileSync } from 'node:fs';
import { AiApi, Configuration } from 'hanzoai';

const read = (name: string) => JSON.parse(readFileSync(new URL(name, import.meta.url), 'utf8'));
const body = read('request.json');
body.model = process.env.KAI_MODEL || body.model;
const expect: Record<string, boolean | Array<string | number>> = read('expect.json');

const ai = new AiApi(new Configuration({ accessToken: process.env.HANZO_API_KEY }));
// The SDK's HTTP error carries the request headers, the API key among them, so keep only status and body.
const { data } = await ai.postDecisions({ aiDecisionsRequest: body }).catch((e) => {
  throw new Error(e.response ? `HTTP ${e.response.status} ${JSON.stringify(e.response.data)}` : e.message);
});
console.log(`${data.id} ${data.model}: ${data.usage.input_tokens} input tokens, ${Math.round(data.latency_ms)} ms`);

let wrong = 0;
for (const name of Object.keys(expect).filter((n) => !(n in data.answers))) {
  wrong++;
  console.log(`  FAIL  ${name}: expected an answer, got none`);
}
for (const [name, a] of Object.entries(data.answers)) {
  let got: boolean | string | number;
  let said: string;
  if (a.type === 'noul') {
    got = a.noul! > 0.5;
    said = `P(true) ${a.noul!.toFixed(3)}`;
  } else if (a.type === 'score') {
    const [top, p] = Object.entries(a.probabilities!).sort((x, y) => y[1] - x[1])[0];
    got = Number(top);
    said = `level ${top} '${a.legend![top]}' at ${p.toFixed(3)} (score ${a.score!.toFixed(2)})`;
  } else {
    got = a.choice!;
    said = `${a.choice} at ${a.answer_confidence!.toFixed(3)}`;
  }
  const want = expect[name];
  if (want === undefined) {
    console.log(`  ----  ${name}: ${said} (not checked: no obvious answer on this input)`);
  } else if (Array.isArray(want) ? want.includes(got as string | number) : got === want) {
    console.log(`  pass  ${name}: ${said}`);
  } else {
    wrong++;
    console.log(`  FAIL  ${name}: ${said}, expected ${JSON.stringify(want)}`);
  }
}
process.exitCode = wrong ? 1 : 0;

#!/usr/bin/env node
// Kai in Claude Code's loop, as a Stop hook and a PreToolUse hook. Rules in code decide first;
// Kai's answers can only tighten what they decide. Both hooks fail open: no key, a slow or
// failing Kai, or an event this file does not read lets the agent carry on as without them.
//
//   stop  Code finds a turn that changed files with no check passing since the last change.
//         Only then is Kai asked whether the closing message reports the work as done and
//         whether a check verified it. Done and unverified sends the turn back to run a check.
//   gate  Before a shell command, or a write outside the project or to a credentials file, a
//         fixed list of actions that cannot be undone is held whatever Kai says, and Kai is
//         asked whether the action is irreversible or reaches beyond this machine. A hold asks
//         the user to confirm. The gate never answers allow or deny, so the user's permission
//         rules still apply after it.
//
// Mode (KAI_HOOK_MODE, else the plugin option `mode`): shadow, the default, asks Kai, logs and
// shows what the hook would have done, and changes nothing; on acts; off does nothing.
// The log, ~/.hanzo/kai-hook/decisions.jsonl, holds probabilities and verdicts, never prompt,
// command or file text.

import { appendFileSync, chmodSync, closeSync, fstatSync, mkdirSync, openSync, readFileSync, readSync, writeFileSync } from "node:fs";
import { createHash } from "node:crypto";
import { homedir } from "node:os";
import { isAbsolute, join, relative, resolve } from "node:path";

const KAI = "https://api.hanzo.ai/v1/decisions";
const HOME = join(homedir(), ".hanzo", "kai-hook");

/** A stop is sent back when Kai reads the closing message as "done" at least this sure, */
const DONE = 0.7;
/** reads the checks run as verifying the change below this, */
const VERIFIED = 0.5;
/** and reads a check as a meaningful way to verify the task at least this sure. */
const APPLIES = 0.5;
/** An action waits for the user when Kai reads it as irreversible or remote at least this sure. */
const HOLD = 0.9;
/** Most stops one session is sent back. */
const BLOCKS = 3;
/**
 * Most characters of JSON in a state; a longer one is not sent. Kai reads each question with up
 * to 1,024 tokens of state, the length it was trained at (README, Limits); at about three
 * characters a token, 3,000 characters stays near that.
 */
const LIMIT = 3000;
/** Bytes read from the end of a transcript, where the current turn is; a longer turn is not read. */
const TAIL = 8 * 1024 * 1024;
/** Wall clock for one Kai call, in ms; hooks.json gives each hook more than this. */
const STOP_MS = 8000;
const GATE_MS = 1500;

// --- configuration ---------------------------------------------------------------------

/** The plugin's options reach a hook as CLAUDE_PLUGIN_OPTION_<KEY>; a hand install sets the plain variables. */
function config() {
  const mode = (process.env.KAI_HOOK_MODE || process.env.CLAUDE_PLUGIN_OPTION_MODE || "shadow").trim().toLowerCase();
  if (mode !== "shadow" && mode !== "on") return null;
  const key = (process.env.CLAUDE_PLUGIN_OPTION_HANZO_API_KEY || process.env.HANZO_API_KEY || "").trim();
  if (!key) return null;
  let url;
  try {
    url = new URL(process.env.KAI_URL || KAI);
  } catch {
    return null;
  }
  const loopback = ["127.0.0.1", "localhost", "[::1]"].includes(url.hostname);
  if (!(url.protocol === "https:" || (url.protocol === "http:" && loopback))) return null;
  if (url.username || url.password) return null;
  return { mode, key, url: url.href, model: process.env.KAI_MODEL || "kai" };
}

// --- what leaves the machine -------------------------------------------------------------

const REDACTED = "<redacted>";

/** Secret shapes replaced in every text sent to Kai; main adds the key in use. */
const SECRETS = [
  [/-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?(?:-----END [A-Z ]*PRIVATE KEY-----|$)/g, REDACTED],
  [/\b((?:bearer|basic)\s+)[\w.~+/-]{16,}=*/gi, `$1${REDACTED}`],
  [/\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|xox[abpr]-[A-Za-z0-9-]{10,})\b/g, REDACTED],
  [/((?:api[_-]?key|secret|token|password|passwd)["']?\s*[:=]\s*["']?)[^\s"'&]{6,}/gi, `$1${REDACTED}`],
  [/(\w+:\/\/[^/\s:@]+:)[^@\s/]+@/g, `$1${REDACTED}@`],
];

/** Terminal escape sequences and control characters other than tab and newline. */
const CONTROL = /\u001b\[[0-9;?]*[ -/]*[@-~]|[\u0000-\u0008\u000b-\u001f\u007f]/g;

/** Characters a text takes inside a JSON string. */
function size(text) {
  return JSON.stringify(text).length - 2;
}

/**
 * A text with secrets redacted, cut so its JSON form holds at most `max` characters plus the
 * cut mark, keeping its start or, with `end`, its end (where a closing message and a runner's
 * summary live). It is redacted before it is cut, so a cut never leaves part of a secret.
 */
function clean(text, max, end = false) {
  let out = String(text ?? "");
  out = end ? out.slice(-16 * max) : out.slice(0, 16 * max);
  out = out.replace(CONTROL, "");
  for (const [pattern, replacement] of SECRETS) out = out.replace(pattern, replacement);
  let keep = Math.min(out.length, max);
  const part = (n) => (end ? out.slice(out.length - n) : out.slice(0, n));
  while (keep > 0 && size(part(keep)) > max) keep = Math.floor(keep * 0.9);
  if (keep === out.length) return out;
  return end ? `[...] ${part(keep)}` : `${part(keep)} [...]`;
}

// --- Kai ---------------------------------------------------------------------------------

/** Kai's own refusal or a malformed answer; its message holds no text of the request. */
class Refused extends Error {}

/** One call of yes/no questions. Throws on anything but a full, well-formed answer. */
async function ask(cfg, state, questions, ms) {
  if (JSON.stringify(state).length > LIMIT) throw new Refused("state over its limit");
  const response = await fetch(cfg.url, {
    method: "POST",
    redirect: "error",
    signal: AbortSignal.timeout(ms),
    headers: { authorization: `Bearer ${cfg.key}`, "content-type": "application/json" },
    body: JSON.stringify({ model: cfg.model, state, questions }),
  });
  if (!response.ok) throw new Refused(`kai answered ${response.status}`);
  const body = await response.json();
  const answers = {};
  for (const id of Object.keys(questions)) {
    const answer = body?.answers?.[id];
    const p = answer?.noul;
    if (answer?.type !== "noul" || typeof p !== "number" || !(p >= 0 && p <= 1)) throw new Refused(`kai gave no answer to ${id}`);
    answers[id] = p;
  }
  return { answers, model: typeof body.model === "string" ? body.model.slice(0, 64) : cfg.model };
}

// --- log and per-session state -----------------------------------------------------------

function home() {
  mkdirSync(HOME, { recursive: true, mode: 0o700 });
  chmodSync(HOME, 0o700);
  return HOME;
}

function hash(text) {
  return createHash("sha256").update(String(text ?? "")).digest("hex").slice(0, 16);
}

function log(row) {
  try {
    const path = join(home(), "decisions.jsonl");
    appendFileSync(path, `${JSON.stringify({ at: new Date().toISOString(), ...row })}\n`, { mode: 0o600 });
    chmodSync(path, 0o600);
  } catch {
    // A log that cannot be written never stops the agent.
  }
}

/** How many stops of this session were already sent back. */
function blocked(session) {
  try {
    return JSON.parse(readFileSync(join(home(), `${hash(session)}.json`), "utf8")).blocks ?? 0;
  } catch {
    return 0;
  }
}

function block(session) {
  try {
    const path = join(home(), `${hash(session)}.json`);
    writeFileSync(path, JSON.stringify({ blocks: blocked(session) + 1 }), { mode: 0o600 });
  } catch {
    // Without the count a session may be sent back more often, never more than once a turn.
  }
}

// --- paths -------------------------------------------------------------------------------

function outside(cwd, file) {
  if (typeof cwd !== "string" || !cwd || !file) return false;
  const rel = relative(cwd, resolve(cwd, file));
  return rel.startsWith("..") || isAbsolute(rel);
}

/** A path relative to the project when it is inside it, else as given. */
function shown(cwd, file) {
  return typeof cwd === "string" && cwd && !outside(cwd, file) ? relative(cwd, resolve(cwd, file)) : file;
}

// --- the transcript ----------------------------------------------------------------------

const FILE_TOOLS = new Set(["Edit", "Write", "MultiEdit", "NotebookEdit"]);

/** A check runner named in a shell command. */
const CHECK =
  /\b(?:(?:npm|pnpm|yarn|bun)\s+(?:run\s+)?(?:test|check|lint|typecheck|build|verify|ci)\b|(?:npx|pnpm|bunx)\s+(?:tsc|jest|vitest|mocha|eslint|biome)\b|pytest|jest|vitest|mocha|tsc\b|eslint|ruff|mypy|cargo\s+(?:test|check|build|clippy|nextest)|go\s+(?:test|vet|build)|make\s+(?:test|check|lint|build)|mvn\s+(?:test|verify)|gradle\w*\s+(?:test|check|build)|dotnet\s+(?:test|build)|node\s+--test|deno\s+(?:test|check)|rspec|mix\s+test|phpunit|swift\s+(?:test|build)|ctest|zig\s+(?:test|build))/;

/** A runner's own summary of failure. */
const FAILED =
  /\b[1-9]\d*\s+(?:failed|failing|failures?|errors?)\b|^FAIL\b|^FAILED\b|test result: FAILED|BUILD FAIL|^error(?:\[E\d+\])?:|\berror TS\d+|Traceback \(most recent call last\)|npm ERR!|exit (?:code|status) [1-9]|^\s*(?:#|ℹ)\s*fail [1-9]/im;

/** A runner's own summary of success. */
const PASSED =
  /test result: ok\.|\b\d+\s+passed\b|^ok\s+\S+|Tests:\s+.*\b\d+ passed|^PASS\b|\b0 (?:failed|failures|errors?)\b|BUILD SUCCESS|Finished `?\w+`? profile|\bAll checks passed\b|^✓|\bpassed\b.*\bin [\d.]+s|^\s*(?:#|ℹ)\s*fail 0\b/im;

function text(content) {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return content.map((part) => (typeof part === "string" ? part : part?.type === "text" ? part.text ?? "" : "")).join("\n");
}

/** The words of a message the user typed, or null for anything else (tool results, notices, commands). */
function typed(entry) {
  if (entry?.type !== "user" || entry.isMeta || entry.isSidechain) return null;
  if (entry.origin && entry.origin.kind !== "human") return null;
  const content = entry.message?.content;
  if (Array.isArray(content) && content.some((part) => part?.type === "tool_result")) return null;
  const words = text(content).trim();
  if (!words || words.startsWith("<command-") || words.startsWith("<local-command-")) return null;
  return words;
}

/** The last TAIL bytes of a transcript as lines, less the first line when it was cut. */
function lines(path) {
  const fd = openSync(path, "r");
  try {
    const bytes = fstatSync(fd).size;
    const start = Math.max(0, bytes - TAIL);
    const buffer = Buffer.alloc(bytes - start);
    readSync(fd, buffer, 0, buffer.length, start);
    const text = buffer.toString("utf8");
    return (start > 0 ? text.slice(text.indexOf("\n") + 1) : text).split("\n");
  } finally {
    closeSync(fd);
  }
}

/** The current turn: the user's last prompt, the file changes and checks since it, the closing message. */
function turn(path) {
  const entries = [];
  for (const line of lines(path)) {
    if (!line) continue;
    try {
      entries.push(JSON.parse(line));
    } catch {
      // A torn last line while the transcript is written: skip it.
    }
  }
  let start = -1;
  for (let i = entries.length - 1; i >= 0; i--) {
    if (typed(entries[i]) !== null) {
      start = i;
      break;
    }
  }
  if (start < 0) return null;
  const calls = new Map();
  const events = [];
  let closing = "";
  for (const entry of entries.slice(start + 1)) {
    if (entry.isSidechain) continue;
    const content = entry.message?.content;
    if (!Array.isArray(content)) continue;
    for (const part of content) {
      if (entry.type === "assistant" && part?.type === "tool_use") {
        calls.set(part.id, part);
      } else if (entry.type === "user" && part?.type === "tool_result") {
        const call = calls.get(part.tool_use_id);
        if (call) events.push({ call, output: text(part.content), error: part.is_error === true });
      }
    }
    if (entry.type === "assistant") {
      const said = text(content).trim();
      if (said) closing = said;
    }
  }
  let last = -1;
  const changed = [];
  events.forEach((event, i) => {
    if (FILE_TOOLS.has(event.call.name) && !event.error) {
      last = i;
      const file = String(event.call.input?.file_path ?? event.call.input?.notebook_path ?? "");
      if (file && !changed.includes(file)) changed.push(file);
    }
  });
  const checks = events
    .slice(last + 1)
    .filter((event) => event.call.name === "Bash" && CHECK.test(String(event.call.input?.command ?? "")))
    .map((event) => ({
      command: String(event.call.input.command),
      output: event.output,
      passed: !event.error && PASSED.test(event.output) && !FAILED.test(event.output),
    }));
  return { task: typed(entries[start]), changed, checks, closing, mutated: last >= 0 };
}

// --- stop --------------------------------------------------------------------------------

const STOP_QUESTIONS = {
  claims_done: {
    type: "noul",
    instructions: "Does `final_message` present the work `task` asks for as finished or working?",
  },
  verified: {
    type: "noul",
    instructions: "Does `checks_run` show a test, build or lint that ran after the change and passed?",
  },
  applies: {
    type: "noul",
    instructions: "Would running the project's tests, build or lint be a meaningful way to check the work `task` asks for?",
  },
};

async function stop(cfg, event) {
  // Already continuing because a stop hook sent this turn back: never twice in one turn.
  if (event.stop_hook_active === true) return null;
  if (typeof event.transcript_path !== "string" || blocked(event.session_id) >= BLOCKS) return null;
  const now = turn(event.transcript_path);
  // Nothing changed this turn, or a check passed after the last change: code has decided.
  if (!now || !now.mutated || now.checks.some((check) => check.passed)) return null;
  const closing = typeof event.last_assistant_message === "string" && event.last_assistant_message.trim() ? event.last_assistant_message : now.closing;
  const state = {
    task: clean(now.task, 600),
    final_message: clean(closing, 800, true),
    changed: now.changed.slice(-5).map((file) => clean(shown(event.cwd, file), 100, true)),
    checks_run: now.checks.slice(-2).map((check) => ({ command: clean(check.command, 120), output: clean(check.output, 250, true) })),
  };
  const started = Date.now();
  const { answers, model } = await ask(cfg, state, STOP_QUESTIONS, STOP_MS);
  const send = answers.claims_done >= DONE && answers.verified < VERIFIED && answers.applies >= APPLIES;
  log({ hook: "stop", session: hash(event.session_id), mode: cfg.mode, model, answers, send, ms: Date.now() - started });
  if (!send) return null;
  if (cfg.mode === "shadow") {
    return {
      systemMessage:
        `Kai (shadow): would have sent this turn back to run a check (done ${answers.claims_done.toFixed(2)}, ` +
        `verified ${answers.verified.toFixed(2)}, a check applies ${answers.applies.toFixed(2)}). Nothing was changed.`,
    };
  }
  block(event.session_id);
  const files = `${now.changed.length} file${now.changed.length === 1 ? "" : "s"}`;
  return {
    decision: "block",
    reason:
      `Kai: the work reads as reported done (${answers.claims_done.toFixed(2)}) after changing ${files}, with no ` +
      "passing test, build or lint since. Run the check that covers this change and report its actual result. " +
      "If no check exists or none can run, say so plainly instead.",
  };
}

// --- gate --------------------------------------------------------------------------------

/**
 * Actions held whatever Kai says: the deterministic floor. Read before anything else, so no
 * shortcut below can let one through.
 */
const FLOOR = [
  // rm with a recursive and a force flag, in any spelling
  /\brm(?=[^;&|\n]*\s(?:-[a-zA-Z]*[rR]|--recursive\b))(?=[^;&|\n]*\s(?:-[a-zA-Z]*f|--force\b))/,
  /\bgit\s+push\b[^;&|\n]*(?:\s--force\b|\s--force-with-lease\b|\s-[a-zA-Z]*f\b|\s\+\S|\s--delete\b|\s-d\b|\s--mirror\b)/,
  /\bgit\s+(?:reset\s+--hard\b|clean\s+-[a-zA-Z]*f|checkout\s+(?:--\s|\.(?:\s|$))|restore\s+(?!--staged\b)|branch\s+-D\b|stash\s+(?:drop|clear)\b)/,
  /\b(?:drop|truncate)\s+(?:table|database|schema)\b/i,
  /\b(?:mkfs|shred)\b|\bdd\b[^;&|\n]*\bof=/,
  /\b(?:kubectl|helm)\s+(?:delete|uninstall)\b|\bterraform\s+(?:destroy|apply)\b/,
  /\b(?:curl|wget)\b[^|\n]*\|\s*(?:sudo\s+)?(?:sh|bash|zsh)\b/,
];

/**
 * One command that reads, or runs the project's own checks, with no chaining, redirection,
 * substitution or second line: Kai is not asked about it.
 */
const READS =
  /^\s*(?:ls|cat|head|tail|less|wc|pwd|echo|printf|which|type|file|stat|du|df|rg|grep|diff|jq|date|whoami|uname|git\s+(?:status|diff|log|show|rev-parse|blame|ls-files|grep)|cargo\s+(?:check|test|build|clippy)|go\s+(?:test|vet|build)|npm\s+(?:test|run\s+(?:test|lint|build|typecheck))|pnpm\s+(?:test|lint|build|typecheck)|pytest|make\s+(?:test|check|lint|build))\b[^;&|<>`$\n\r]*$/;

/** Files whose change version control does not keep or which carry credentials. */
const SENSITIVE = /(?:^|\/)(?:\.env(?:\.[\w.-]+)?|\.npmrc|\.netrc|id_[a-z0-9]+|[^/]+\.(?:pem|key|p12))$|(?:^|\/)\.(?:ssh|aws|kube|gnupg)\//;

const GATE_QUESTIONS = {
  irreversible: {
    type: "noul",
    instructions: "Would `action` change or delete something that version control or a backup cannot restore?",
  },
  remote: {
    type: "noul",
    instructions: "Does `action` change a system beyond this machine, such as pushing, publishing, deploying, sending or paying?",
  },
};


async function gate(cfg, event) {
  const tool = String(event.tool_name ?? "");
  const input = event.tool_input ?? {};
  let action;
  let floor = false;
  if (tool === "Bash") {
    const command = String(input.command ?? "");
    floor = FLOOR.some((pattern) => pattern.test(command));
    if (!floor && READS.test(command)) return null;
    action = { tool, command: clean(command, 800) };
  } else if (FILE_TOOLS.has(tool)) {
    const file = String(input.file_path ?? input.notebook_path ?? "");
    // A write inside the project that version control keeps: nothing to ask.
    if (!outside(event.cwd, file) && !SENSITIVE.test(file)) return null;
    action = { tool, file: clean(file, 300, true) };
  } else {
    return null;
  }
  const state = { action, cwd: clean(event.cwd, 200, true), permission_mode: clean(event.permission_mode, 30) };
  let answers = null;
  let model = cfg.model;
  const started = Date.now();
  try {
    ({ answers, model } = await ask(cfg, state, GATE_QUESTIONS, GATE_MS));
  } catch (error) {
    // Without Kai only the floor holds.
    if (!floor) throw error;
  }
  const read = answers === null ? 0 : Math.max(answers.irreversible, answers.remote);
  const hold = floor || read >= HOLD;
  log({ hook: "gate", session: hash(event.session_id), mode: cfg.mode, tool, model, answers, floor, hold, ms: Date.now() - started });
  if (!hold) return null;
  const why = floor
    ? "it matches an action that cannot be undone"
    : `it reads as ${answers.irreversible >= answers.remote ? "irreversible" : "reaching beyond this machine"} (${read.toFixed(2)})`;
  if (cfg.mode === "shadow") return { systemMessage: `Kai (shadow): would have asked before this ${tool} call: ${why}. Nothing was changed.` };
  return {
    hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: `Kai: ${why}. Confirm before it runs.` },
  };
}

// --- entry -------------------------------------------------------------------------------

async function stdin() {
  const chunks = [];
  for await (const chunk of process.stdin) chunks.push(chunk);
  return Buffer.concat(chunks).toString("utf8");
}

/** What a failure was, without any text of the request or the answer. */
function failure(error) {
  return error instanceof Refused ? error.message : String(error?.name ?? "Error");
}

async function main(hook) {
  if (hook !== "stop" && hook !== "gate") return;
  const cfg = config();
  if (!cfg) return;
  if (cfg.key.length >= 8) SECRETS.push([new RegExp(cfg.key.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "g"), REDACTED]);
  let event;
  try {
    event = JSON.parse(await stdin());
  } catch {
    return;
  }
  if (event === null || typeof event !== "object") return;
  let output;
  try {
    output = hook === "stop" ? await stop(cfg, event) : await gate(cfg, event);
  } catch (error) {
    log({ hook, session: hash(event.session_id), mode: cfg.mode, error: failure(error) });
    return;
  }
  // One JSON object on stdout, exit 0: Claude Code's hook output. Silence is the normal flow.
  if (output) process.stdout.write(`${JSON.stringify(output)}\n`);
}

await main(process.argv[2]);

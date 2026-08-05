const { GoogleGenerativeAI } = require('@google/generative-ai');
const prompts = require('./prompts');
const modelRouter = require('./modelRouter');
const aiCache = require('./aiCache');
const monitoring = require('../monitoringService');

// Central AI execution engine (v13 §11): prompt composition -> cache lookup ->
// generate with retry/fallback -> cache store -> logging.
//
// All Gemini access funnels through here, which is what keeps the API key
// backend-only (v13 §10) — the Flutter client never sees it.

const API_KEY = process.env.GEMINI_API_KEY;
const MOCK_MODE = !API_KEY;
const MAX_ATTEMPTS = Number(process.env.AI_MAX_ATTEMPTS || 3);
const BASE_BACKOFF_MS = Number(process.env.AI_BACKOFF_MS || 500);

const client = MOCK_MODE ? null : new GoogleGenerativeAI(API_KEY);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/// Rate limits and transient 5xx are worth retrying; malformed requests and
/// auth failures are not — retrying those just burns time and quota.
function isRetryable(err) {
  const msg = String(err?.message || '').toLowerCase();
  const status = err?.status || err?.code;
  if (status === 429 || status === 503 || status === 500) return true;
  return (
    msg.includes('rate limit') ||
    msg.includes('quota') ||
    msg.includes('overloaded') ||
    msg.includes('timeout') ||
    msg.includes('unavailable') ||
    msg.includes('fetch failed')
  );
}

async function callModel(modelName, prompt) {
  const model = client.getGenerativeModel({ model: modelName });
  const result = await model.generateContent(prompt);
  return result.response.text();
}

/**
 * Runs an AI task end to end.
 *
 * @param {string} task      key in prompts.PROMPTS
 * @param {Array}  args      arguments passed to that task's build()
 * @param {object} options   { cache = true, mockValue }
 */
async function run(task, args = [], { cache = true, mockValue } = {}) {
  const version = prompts.versionOf(task);
  const model = modelRouter.modelFor(task);
  const prompt = prompts.compose(task, args);

  if (MOCK_MODE) {
    return mockValue !== undefined
      ? mockValue
      : `[mock response — set GEMINI_API_KEY for real output]\n${String(args[0] || '').slice(0, 120)}...`;
  }

  const cacheKey = aiCache.keyFor({ task, version, model, prompt });
  if (cache) {
    const hit = await aiCache.get(cacheKey);
    if (hit !== null) {
      monitoring.write('info', 'ai_cache_hit', { task, model });
      return hit;
    }
  }

  let lastError;
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt += 1) {
    // Final attempt drops the strict output template — formatting demands are
    // the usual cause of repeated failures (v13 §9 fallback prompts).
    const isFinal = attempt === MAX_ATTEMPTS;
    const activePrompt = isFinal ? prompts.compose(task, args, { fallback: true }) : prompt;

    try {
      const started = Date.now();
      const text = await callModel(model, activePrompt);
      monitoring.write('info', 'ai_call', { task, model, attempt, ms: Date.now() - started, fallback: isFinal });

      if (cache && !isFinal) await aiCache.set(cacheKey, text, { task, model, version });
      return text;
    } catch (err) {
      lastError = err;
      monitoring.logAiFailure(task, `attempt ${attempt}/${MAX_ATTEMPTS}: ${err.message}`);

      if (!isRetryable(err) || isFinal) break;
      // Exponential backoff so a rate limit isn't hammered.
      await sleep(BASE_BACKOFF_MS * 2 ** (attempt - 1));
    }
  }

  throw Object.assign(new Error(`AI task "${task}" failed: ${lastError?.message}`), {
    code: 'AI_FAILED',
    cause: lastError,
  });
}

module.exports = { run, MOCK_MODE, isRetryable, MAX_ATTEMPTS };

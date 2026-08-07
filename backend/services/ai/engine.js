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

/// A daily-quota exhaustion, as opposed to a momentary rate limit. Retrying
/// the same model is pointless — the allowance is gone until tomorrow — so
/// this switches models instead of backing off.
function isQuotaExhausted(err) {
  const msg = String(err?.message || '');
  return /PerDay|per day|GenerateRequestsPerDay/i.test(msg) || /quotaValue.{0,6}"?0"?\b/.test(msg);
}

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
async function run(task, args = [], { cache = true, mockValue, language = null } = {}) {
  const version = prompts.versionOf(task);
  const model = modelRouter.modelFor(task);
  const prompt = prompts.compose(task, args, { language });

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

  // Outer loop walks the model chain: free-tier quota is per model and small,
  // so when one model's daily allowance runs out the next one usually still
  // has room. Inner loop is the per-model retry with backoff.
  outer: for (const activeModel of modelRouter.modelChainFor(task)) {
    for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt += 1) {
      // Final attempt drops the strict output template — formatting demands are
      // the usual cause of repeated failures (v13 §9 fallback prompts).
      const isFinal = attempt === MAX_ATTEMPTS;
      // The language instruction survives the fallback: dropping the output
      // template is about formatting, and answering in the wrong language
      // would be a worse failure than a badly formatted one.
      const activePrompt = isFinal ? prompts.compose(task, args, { fallback: true, language }) : prompt;

      try {
        const started = Date.now();
        const text = await callModel(activeModel, activePrompt);
        monitoring.write('info', 'ai_call', {
          task,
          model: activeModel,
          attempt,
          ms: Date.now() - started,
          fallback: isFinal,
        });

        if (cache && !isFinal) await aiCache.set(cacheKey, text, { task, model: activeModel, version });
        return text;
      } catch (err) {
        lastError = err;
        monitoring.logAiFailure(task, `${activeModel} attempt ${attempt}/${MAX_ATTEMPTS}: ${err.message}`);

        // Daily allowance gone — no amount of waiting helps, move on.
        if (isQuotaExhausted(err)) continue outer;
        if (!isRetryable(err) || isFinal) break outer;
        // Exponential backoff so a momentary rate limit isn't hammered.
        await sleep(BASE_BACKOFF_MS * 2 ** (attempt - 1));
      }
    }
  }

  throw Object.assign(new Error(`AI task "${task}" failed: ${lastError?.message}`), {
    code: 'AI_FAILED',
    cause: lastError,
  });
}

module.exports = { run, MOCK_MODE, isRetryable, MAX_ATTEMPTS };

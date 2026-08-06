// Per-task model routing (v13 §2).
//
// Everything defaults to GEMINI_MODEL, but each task can be pointed at a
// different model via env — e.g. a cheaper/faster model for translation and
// a stronger one for market-impact reasoning — without touching code.
const DEFAULT_MODEL = process.env.GEMINI_MODEL || 'gemini-flash-lite-latest';

// Free-tier daily quota is metered PER MODEL, and it is small — measured at 20
// requests/day for gemini-flash-latest. When one model's daily allowance is
// gone, another model's is usually still intact, so a task falls through this
// list rather than failing outright. Order is best-quality-first.
const FALLBACK_MODELS = (process.env.GEMINI_FALLBACK_MODELS ||
  'gemini-flash-lite-latest,gemini-flash-latest,gemini-2.0-flash-lite,gemini-2.0-flash')
  .split(',')
  .map((m) => m.trim())
  .filter(Boolean);

const ROUTES = {
  summary: process.env.GEMINI_MODEL_SUMMARY,
  summaryPlain: process.env.GEMINI_MODEL_SUMMARY,
  translate: process.env.GEMINI_MODEL_TRANSLATE,
  impact: process.env.GEMINI_MODEL_IMPACT,
  explain: process.env.GEMINI_MODEL_EXPLAIN,
  chat: process.env.GEMINI_MODEL_CHAT,
  inFocus: process.env.GEMINI_MODEL_INFOCUS,
  marketBrief: process.env.GEMINI_MODEL_INFOCUS,
};

function modelFor(taskName) {
  return ROUTES[taskName] || DEFAULT_MODEL;
}

/// The configured model first, then the rest of the fallback chain.
function modelChainFor(taskName) {
  const primary = modelFor(taskName);
  return [primary, ...FALLBACK_MODELS.filter((m) => m !== primary)];
}

module.exports = { modelFor, modelChainFor, DEFAULT_MODEL, FALLBACK_MODELS, ROUTES };

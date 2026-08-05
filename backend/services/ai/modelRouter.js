// Per-task model routing (v13 §2).
//
// Everything defaults to GEMINI_MODEL, but each task can be pointed at a
// different model via env — e.g. a cheaper/faster model for translation and
// a stronger one for market-impact reasoning — without touching code.
const DEFAULT_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash';

const ROUTES = {
  summary: process.env.GEMINI_MODEL_SUMMARY,
  summaryPlain: process.env.GEMINI_MODEL_SUMMARY,
  translate: process.env.GEMINI_MODEL_TRANSLATE,
  impact: process.env.GEMINI_MODEL_IMPACT,
  explain: process.env.GEMINI_MODEL_EXPLAIN,
  chat: process.env.GEMINI_MODEL_CHAT,
};

function modelFor(taskName) {
  return ROUTES[taskName] || DEFAULT_MODEL;
}

module.exports = { modelFor, DEFAULT_MODEL, ROUTES };

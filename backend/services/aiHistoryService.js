const { db } = require('../config/firebaseAdmin');

const MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
const MAX_STORED_CHARS = 4000;

function truncate(value) {
  const text = typeof value === 'string' ? value : JSON.stringify(value ?? '');
  return text.length > MAX_STORED_CHARS ? `${text.slice(0, MAX_STORED_CHARS)}…[truncated]` : text;
}

// Fire-and-forget AI audit log (v11 `ai_history`). Deliberately never awaited
// by callers and never throws: a logging failure must not break or slow down
// the user-facing AI response.
function log({ userId, action, prompt, response }) {
  db.collection('ai_history')
    .add({
      userId: userId || null,
      action,
      model: MODEL,
      prompt: truncate(prompt),
      response: truncate(response),
      timestamp: Date.now(),
    })
    .catch((err) => console.error('[ai_history] write failed:', err.message));
}

module.exports = { log };

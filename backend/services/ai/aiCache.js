const crypto = require('crypto');
const { db } = require('../../config/firebaseAdmin');

// AI response cache (v13 §8). The same article being summarised twice — by
// the pipeline and then by a user tapping "AI Summary" — should cost one
// Gemini call, not two.
//
// Key includes the prompt version and model, so changing either naturally
// invalidates old entries rather than serving stale output.
const TTL_MS = Number(process.env.AI_CACHE_TTL_MS || 24 * 60 * 60 * 1000);
const COLLECTION = 'ai_cache';

function keyFor({ task, version, model, prompt }) {
  const hash = crypto.createHash('sha256').update(`${task}|${version}|${model}|${prompt}`).digest('hex');
  return hash.slice(0, 40);
}

async function get(key) {
  try {
    const doc = await db.collection(COLLECTION).doc(key).get();
    if (!doc.exists) return null;

    const { response, cachedAt } = doc.data();
    if (!cachedAt || Date.now() - cachedAt > TTL_MS) return null;
    return response;
  } catch (err) {
    // A cache failure must never break the AI call — treat as a miss.
    console.error('[ai_cache] read failed:', err.message);
    return null;
  }
}

async function set(key, response, meta = {}) {
  if (response === undefined || response === null) return;
  try {
    await db.collection(COLLECTION).doc(key).set({ response, cachedAt: Date.now(), ...meta });
  } catch (err) {
    console.error('[ai_cache] write failed:', err.message);
  }
}

module.exports = { keyFor, get, set, TTL_MS, COLLECTION };

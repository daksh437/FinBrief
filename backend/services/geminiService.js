const engine = require('./ai/engine');
const prompts = require('./ai/prompts');

// Public AI surface for the rest of the backend. The heavy lifting (prompt
// composition, model routing, caching, retry/fallback, logging) lives in
// services/ai/*; this file just maps tasks to typed results.
//
// Exported signatures are intentionally unchanged from before the v13 engine
// landed, so aiController and the news pipeline needed no edits.

const MOCK_MODE = engine.MOCK_MODE;

// Models often wrap JSON in prose or code fences — pull out the first object.
function parseJson(raw, fallback) {
  try {
    const match = raw.match(/\{[\s\S]*\}/);
    return match ? JSON.parse(match[0]) : fallback;
  } catch {
    return fallback;
  }
}

async function translateToHindi(text) {
  return engine.run('translate', [text]);
}

// Plain-prose summary. Kept separate from summarizeStructured() because the
// voice-summary route feeds this straight into TTS, which must speak
// sentences rather than JSON.
async function summarize(text) {
  return engine.run('summaryPlain', [text]);
}

// Adds key points + a confidence score on top of the prose summary. The
// `summary` field stays a plain string so existing clients keep working.
async function summarizeStructured(text) {
  if (MOCK_MODE) {
    return {
      summary: '[mock response — set GEMINI_API_KEY for real output] Markets moved on the back of this news.',
      keyPoints: ['Mock key point one.', 'Mock key point two.', 'Mock key point three.'],
      confidence: 0.5,
    };
  }

  const raw = await engine.run('summary', [text]);
  const parsed = parseJson(raw, { summary: raw, keyPoints: [], confidence: 0 });
  return {
    summary: typeof parsed.summary === 'string' ? parsed.summary : raw,
    keyPoints: Array.isArray(parsed.keyPoints) ? parsed.keyPoints.map(String) : [],
    confidence: typeof parsed.confidence === 'number' ? parsed.confidence : 0,
  };
}

async function analyzeImpact(text) {
  if (MOCK_MODE) {
    return {
      sentiment: 'neutral',
      confidence: 0.5,
      reason: 'Mock mode — set GEMINI_API_KEY for real analysis.',
      affectedSectors: ['IT', 'Banking'],
    };
  }

  const raw = await engine.run('impact', [text]);
  const parsed = parseJson(raw, { sentiment: 'neutral', confidence: 0, reason: raw });
  return {
    sentiment: parsed.sentiment || 'neutral',
    confidence: typeof parsed.confidence === 'number' ? parsed.confidence : 0,
    reason: parsed.reason || raw,
    affectedSectors: Array.isArray(parsed.affectedSectors) ? parsed.affectedSectors.map(String) : [],
  };
}

async function explain(text, mode) {
  if (!prompts.PROMPTS.explain.modes.includes(mode)) {
    throw Object.assign(new Error('Unknown explain mode'), { code: 'UNKNOWN_MODE' });
  }
  return engine.run('explain', [text, mode]);
}

/**
 * Context-aware chat (v13 §7).
 * @param messages [{ role: 'user'|'assistant', text }]
 * @param context  optional string built by chatContextService
 */
async function chat(messages, context = null) {
  if (MOCK_MODE) {
    return '[mock response — set GEMINI_API_KEY for real output] I am your AI financial assistant. Ask me about markets, stocks, or news.';
  }

  // Fold prior turns into the prompt so the model sees the conversation.
  const history = messages
    .slice(0, -1)
    .map((m) => `${m.role === 'assistant' ? 'Assistant' : 'User'}: ${m.text}`)
    .join('\n');
  const last = messages[messages.length - 1]?.text || '';
  const question = history ? `${history}\nUser: ${last}` : last;

  // Chat is conversational and context-dependent, so caching would serve
  // stale answers — disabled deliberately.
  return engine.run('chat', [question, context], { cache: false });
}

module.exports = {
  translateToHindi,
  summarize,
  summarizeStructured,
  analyzeImpact,
  explain,
  chat,
  MOCK_MODE,
};

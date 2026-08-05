// Versioned prompt templates (v13 §3).
//
// Each task defines: a system prompt (role/behaviour), a user prompt builder,
// an optional output template, and a version string. Bump `version` whenever
// a prompt changes — it's part of the AI cache key, so old cached responses
// are naturally invalidated instead of silently serving stale output.

const SYSTEM_BASE =
  'You are FinBrief, a financial news assistant for Indian retail investors. ' +
  'Be accurate, concise and neutral. Never give personalised investment advice. ' +
  'Preserve company names, tickers and numbers exactly as written.';

const PROMPTS = {
  summary: {
    version: 'v2',
    system: `${SYSTEM_BASE} You summarise news so it can be read in about 30 seconds.`,
    output:
      'Respond as strict JSON with keys "summary" (2-3 plain-English sentences), ' +
      '"keyPoints" (array of 2-4 short bullet strings), and "confidence" (0-1 number).',
    build: (text) => `Summarise this financial news.\n\nText:\n${text}`,
  },

  // Deliberately separate from `summary`: the voice-summary route feeds this
  // straight into TTS, which must speak prose rather than JSON.
  summaryPlain: {
    version: 'v1',
    system: `${SYSTEM_BASE} You summarise news in plain prose suitable for reading aloud.`,
    output: 'Return only the summary text. No JSON, no markdown, no bullet points.',
    build: (text) => `Summarise this financial news in 2-3 short sentences.\n\nText:\n${text}`,
  },

  translate: {
    version: 'v2',
    system: `${SYSTEM_BASE} You translate financial news into simple, conversational Hindi.`,
    output:
      'Return only the Hindi translation. Keep numbers, tickers, company names and ' +
      'financial terms in their original form where no natural Hindi equivalent exists.',
    build: (text) => `Translate this financial news to Hindi.\n\nText:\n${text}`,
  },

  impact: {
    version: 'v2',
    system: `${SYSTEM_BASE} You assess how news is likely to move markets.`,
    output:
      'Respond as strict JSON with keys "sentiment" (one of "bullish", "bearish", "neutral"), ' +
      '"confidence" (0-1 number), "reason" (one sentence), and "affectedSectors" ' +
      '(array of 1-4 short sector names, e.g. "IT", "Banking", "Energy").',
    build: (text) => `Analyse the market impact of this financial news.\n\nText:\n${text}`,
  },

  explain: {
    version: 'v1',
    system: `${SYSTEM_BASE} You explain financial news clearly to non-experts.`,
    output: 'Return 2-4 short sentences of plain text.',
    build: (text, mode) => {
      const asks = {
        'why-it-matters': 'Explain why this matters for an ordinary Indian retail investor.',
        'future-impact':
          'Explain the likely market impact over the coming weeks. Make clear this is an ' +
          'informed view, not a prediction or investment advice.',
        beginner:
          'Explain this to a complete beginner who knows nothing about markets. Avoid jargon ' +
          'and define any necessary terms.',
        hindi: 'Explain this in simple, conversational Hindi for a beginner investor.',
      };
      return `${asks[mode]}\n\nText:\n${text}`;
    },
    modes: ['why-it-matters', 'future-impact', 'beginner', 'hindi'],
  },

  chat: {
    version: 'v2',
    system:
      `${SYSTEM_BASE} You answer questions about markets and financial news. ` +
      'If context is supplied below, prefer it over your own general knowledge and say ' +
      'when something falls outside it. Never invent prices or figures.',
    output: 'Answer conversationally. Markdown is allowed.',
    build: (question, context) =>
      context ? `Context:\n${context}\n\nQuestion:\n${question}` : question,
  },
};

/// Simpler prompt used when the primary one has failed repeatedly (v13 §9) —
/// drops strict output formatting, which is the usual cause of parse failures.
const FALLBACK = {
  system: SYSTEM_BASE,
  output: 'Answer briefly in plain text.',
};

/// Assembles the final prompt string sent to the model.
function compose(taskName, args = [], { fallback = false } = {}) {
  const task = PROMPTS[taskName];
  if (!task) throw Object.assign(new Error(`Unknown prompt task: ${taskName}`), { code: 'UNKNOWN_TASK' });

  const system = fallback ? FALLBACK.system : task.system;
  const output = fallback ? FALLBACK.output : task.output;
  const user = task.build(...args);

  return `${system}\n\n${output}\n\n${user}`;
}

function versionOf(taskName) {
  return PROMPTS[taskName]?.version || 'v0';
}

module.exports = { PROMPTS, FALLBACK, compose, versionOf, SYSTEM_BASE };

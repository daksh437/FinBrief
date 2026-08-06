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

  // Explains WHAT a story concerns, not which way it should move a price.
  //
  // This used to return a bullish/bearish/neutral label. Attaching a direction
  // to a named security is what turns commentary into something that reads as
  // a recommendation, which is the line SEBI's investment-adviser and
  // research-analyst regulations sit on. Describing the story and the parts of
  // the market it touches keeps the useful half without the call.
  impact: {
    version: 'v3',
    system:
      `${SYSTEM_BASE} You explain which parts of the market a story concerns and why. ` +
      'You never say whether something will rise or fall, never label news as positive ' +
      'or negative for a security, and never predict prices.',
    output:
      'Respond as strict JSON with keys "reason" (one or two sentences explaining what ' +
      'the news concerns, in factual terms), and "affectedSectors" (array of 1-4 short ' +
      'sector names, e.g. "IT", "Banking", "Energy").',
    build: (text) => `Which parts of the market does this financial news concern, and why?\n\nText:\n${text}`,
  },

  // "In focus today" — grounded in the day's actual headlines rather than a
  // stored list, and deliberately observation rather than recommendation.
  //
  // The bullish/bearish label was removed: naming a security and attaching a
  // direction to it is the thing that reads as a call, however it is worded.
  // What is left — which companies the news is about, and what the news says —
  // is reporting.
  inFocus: {
    version: 'v2',
    system:
      `${SYSTEM_BASE} You identify which companies or assets are in the news today and why. ` +
      'You never recommend buying, selling or holding anything, never say whether ' +
      'something will rise or fall, and never predict prices.',
    output:
      'Respond as strict JSON: an array of 3 objects with keys "symbol" (NSE ticker or ' +
      'asset code, uppercase), "name" (company or asset name), and "reason" (one short ' +
      'factual sentence stating what the news says about it). ' +
      'Only include names that actually appear in the headlines provided.',
    build: (headlines) =>
      `From these headlines, pick the 3 companies or assets most in focus today.\n\n` +
      `Headlines:\n${headlines}`,
  },

  // One-line market read for the Home screen, also grounded in real headlines.
  marketBrief: {
    version: 'v1',
    system: `${SYSTEM_BASE} You summarise the overall market mood in a single sentence.`,
    output:
      'Return one plain sentence of at most 25 words. No JSON, no markdown, no ticker ' +
      'recommendations, no price predictions.',
    build: (headlines) =>
      `What is the overall mood of the Indian market today, based on these headlines?\n\n` +
      `Headlines:\n${headlines}`,
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

// Minimal smoke test — expand as real endpoints get test coverage.
const assert = require('assert');

process.env.DEV_SKIP_LIMITS = 'true';
process.env.GEMINI_API_KEY = '';
process.env.NEWS_API_KEY = '';
process.env.GOOGLE_TTS_API_KEY = '';

const gemini = require('../services/geminiService');
const news = require('../services/newsService');
const tts = require('../services/ttsService');
const processor = require('../services/newsProcessor');
const { rateLimit } = require('../middleware/rateLimit');
const aiPrompts = require('../services/ai/prompts');
const aiCache = require('../services/ai/aiCache');
const aiEngine = require('../services/ai/engine');

async function run() {
  assert.strictEqual(gemini.MOCK_MODE, true, 'gemini should be in mock mode without an API key');
  // News is deliberately NEVER in mock mode now: the RSS provider needs no key
  // and is always available, so the app always has real headlines.
  assert.strictEqual(news.MOCK_MODE, false, 'RSS provider should keep news out of mock mode without any API key');
  assert.strictEqual(tts.MOCK_MODE, true, 'tts service should be in mock mode without an API key');

  const articles = await news.getFeed();
  assert.ok(Array.isArray(articles) && articles.length > 0, 'mock feed should return sample articles');

  const translated = await gemini.translateToHindi('Sensex hits record high');
  assert.ok(typeof translated === 'string' && translated.length > 0, 'mock translate should return a string');

  const summarized = await gemini.summarize('Sensex hits record high on IT rally');
  const { audioContent, mock } = await tts.synthesize(summarized, 'en-IN');
  assert.strictEqual(mock, true, 'mock tts should flag mock: true');
  assert.ok(Buffer.from(audioContent, 'base64').length > 0, 'mock audioContent should decode to bytes');

  // --- news processing pipeline (v12) ---
  const now = new Date().toISOString();
  const deduped = processor.dedupe([
    { title: 'Sensex Hits Record High!', publishedAt: now },
    { title: 'sensex hits record high', publishedAt: now },
    { title: 'RBI cuts repo rate', publishedAt: now },
  ]);
  assert.strictEqual(deduped.length, 2, 'headline variants should dedupe to one');

  assert.strictEqual(processor.classifyCategory({ title: 'Bitcoin surges' }), 'Crypto');
  assert.strictEqual(processor.classifyCategory({ title: 'RBI holds repo rate' }), 'Economy');
  assert.deepStrictEqual(processor.extractTags({ title: 'Reliance and TCS gain' }), ['RELIANCE', 'TCS']);
  assert.strictEqual(processor.assignPriority({ title: 'Breaking: market crash', publishedAt: now }), 'high');

  const sorted = processor.process([
    { title: 'Weekly wrap', publishedAt: new Date(Date.now() - 9e7).toISOString() },
    { title: 'Breaking: Sensex plunge', publishedAt: now },
  ]);
  assert.strictEqual(sorted[0].priority, 'high', 'high-priority articles must sort first');

  // --- rate limiter (v11) ---
  const limiter = rateLimit({ name: 'test', windowMs: 60_000, max: 2 });
  const fire = (uid) =>
    new Promise((resolve) => {
      const res = {
        set() {},
        status(c) { this.code = c; return this; },
        json() { resolve(this.code); },
      };
      limiter({ user: { uid }, ip: 'test' }, res, () => resolve(200));
    });

  assert.strictEqual(await fire('u1'), 200);
  assert.strictEqual(await fire('u1'), 200);
  assert.strictEqual(await fire('u1'), 429, 'third request should be rate limited');
  assert.strictEqual(await fire('u2'), 200, 'a different user must have its own bucket');

  // --- AI engine (v13) ---
  const composed = aiPrompts.compose('summary', ['Sensex up 400']);
  assert.ok(composed.includes('FinBrief'), 'prompt must include the system prompt');
  assert.ok(composed.includes('strict JSON'), 'prompt must include the output template');
  assert.ok(composed.includes('Sensex up 400'), 'prompt must include the user text');
  assert.ok(
    !aiPrompts.compose('summary', ['x'], { fallback: true }).includes('strict JSON'),
    'fallback prompt should drop strict output formatting'
  );

  const kBase = aiCache.keyFor({ task: 's', version: 'v1', model: 'm', prompt: 'p' });
  assert.notStrictEqual(
    kBase,
    aiCache.keyFor({ task: 's', version: 'v2', model: 'm', prompt: 'p' }),
    'a prompt version bump must invalidate the cache key'
  );
  assert.notStrictEqual(
    kBase,
    aiCache.keyFor({ task: 's', version: 'v1', model: 'm2', prompt: 'p' }),
    'a model change must invalidate the cache key'
  );

  assert.strictEqual(aiEngine.isRetryable({ status: 429 }), true, '429 should retry');
  assert.strictEqual(aiEngine.isRetryable(new Error('invalid argument')), false, 'bad requests should not retry');

  // Public AI surface must stay stable for aiController / the pipeline.
  const structured = await gemini.summarizeStructured('Sensex hits record high');
  assert.deepStrictEqual(Object.keys(structured).sort(), ['confidence', 'keyPoints', 'summary']);
  const impactResult = await gemini.analyzeImpact('x');
  assert.ok('affectedSectors' in impactResult, 'impact must include affectedSectors');

  console.log('All smoke tests passed.');
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});

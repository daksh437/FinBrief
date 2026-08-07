const { db } = require('../config/firebaseAdmin');
const gemini = require('./geminiService');
const newsProviders = require('./newsProviders');
const newsService = require('./newsService');
const processor = require('./newsProcessor');
const monitoring = require('./monitoringService');

// v12 §3 backend flow:
//   fetch -> dedupe -> save raw -> AI summary -> Hindi -> impact -> Firestore
//
// AI enrichment is the expensive step, so it is applied to at most
// AI_ENRICH_LIMIT articles per run and results are persisted — an article is
// never re-enriched once stored.
const AI_ENRICH_LIMIT = Number(process.env.AI_ENRICH_LIMIT || 3);

/// Which of these headlines have already been enriched.
///
/// This used to load the 200 most recently processed articles and treat
/// anything outside that window as new. It quietly cost a fortune: RSS feeds
/// carry the same article for days, the pipeline runs 288 times a day across
/// categories, and every run pushed older entries out of the window. An
/// article that fell out looked new again, was re-enriched, was re-saved with
/// a fresh timestamp, and pushed something else out in turn — a churn loop
/// that billed roughly 550 AI calls a day for about 150 genuinely new stories.
///
/// Documents are keyed by headline hash, so existence can be checked exactly
/// instead of guessed from a window. Firestore reads are a rounding error next
/// to a Gemini call.
async function loadSeenHashes(hashes = []) {
  if (!hashes.length) return new Set();

  try {
    const seen = new Set();
    // getAll caps at 300 refs per call; a feed page is ~150, but batch anyway
    // so a larger limit can't break this.
    for (let i = 0; i < hashes.length; i += 300) {
      const refs = hashes.slice(i, i + 300).map((h) => db.collection('news').doc(h));
      const docs = await db.getAll(...refs);
      docs.forEach((d) => {
        if (d.exists) seen.add(d.id);
      });
    }
    return seen;
  } catch (err) {
    monitoring.logApiFailure('firestore:news', err.message);
    // Treating everything as seen on failure is the safe direction: skipping a
    // cycle costs nothing, re-enriching the whole feed costs money.
    return new Set(hashes);
  }
}

/// Runs the full AI pipeline for one article (v12 §4).
/// Pre-computes only what something actually reads.
///
/// This used to make THREE Gemini calls per article — summary, Hindi
/// translation and impact — and store all three. Only `aiSummary` was ever
/// read back (pushEngine uses it as the notification body, chatContext as
/// recent-news context). The Hindi translation and the impact analysis were
/// written to Firestore and never looked at by anything, because users get
/// both on demand from the article screen, where the AI cache already keeps a
/// repeat request free.
///
/// So two of every three calls here were paid for and thrown away. At a few
/// hundred new articles a day that was the single largest consumer of the
/// Gemini budget, spent on nothing.
async function enrich(article) {
  const source = article.summary || article.title;
  const result = {
    aiSummary: null,
    keyPoints: [],
    followUpQuestions: [],
  };

  try {
    const structured = await gemini.summarizeStructured(source);
    result.aiSummary = structured.summary;
    result.keyPoints = structured.keyPoints;
  } catch (err) {
    monitoring.logAiFailure('summary', err.message);
  }

  // Suggested follow-ups are derived locally rather than via another Gemini
  // call — a 2nd AI request per article isn't worth the cost/latency.
  result.followUpQuestions = [
    'Why does this matter for my portfolio?',
    `What could happen next in ${article.category || 'this sector'}?`,
    'Explain this in simple terms',
  ];

  return result;
}

async function save(article, enrichment) {
  const doc = {
    headline: article.title,
    headlineHash: article.headlineHash,
    source: article.source || null,
    url: article.url || null,
    imageUrl: article.imageUrl || null,
    category: article.category,
    tags: article.tags || [],
    priority: article.priority,
    language: 'en',
    publishedAt: article.publishedAt || null,
    processedAt: Date.now(),
    ...enrichment,
  };

  // Keyed by headline hash so a re-run can't create duplicate documents.
  await db.collection('news').doc(article.headlineHash).set(doc, { merge: true });
  return doc;
}

/// Fetches, processes and enriches the latest news.
/// Returns the newly-stored articles (already priority-sorted).
async function run({ category = 'business', limit = 20 } = {}) {
  const started = Date.now();

  // Prefer a configured provider; fall back to the existing news service
  // (which itself falls back to mock data when no keys are set).
  let raw = [];
  let providerName = 'mock';
  const fromProvider = await newsProviders.fetchNews({ category, limit });
  if (fromProvider) {
    raw = fromProvider.articles;
    providerName = fromProvider.provider;
  } else {
    try {
      raw = await newsService.getFeed({ category, pageSize: limit });
      providerName = newsService.MOCK_MODE ? 'mock' : 'newsapi-legacy';
    } catch (err) {
      monitoring.logApiFailure('news', err.message);
      return { stored: [], provider: providerName, error: err.message };
    }
  }

  // Hash first so existence can be checked for exactly these headlines,
  // rather than against a rolling window of whatever was processed recently.
  const hashes = raw.filter((a) => a.title).map((a) => processor.headlineHash(a.title));
  const seen = await loadSeenHashes(hashes);
  const processed = processor.process(raw, seen);

  // Only high-priority stories get an AI summary.
  //
  // The summary has exactly one consumer: the body of an instant breaking
  // notification, which only fires for high priority. sendBrief uses the raw
  // headline, and nothing else reads it back. Enriching the top few of every
  // run regardless of priority meant paying for ~500 summaries a day to send a
  // handful of notifications — most were generated, stored, and never looked
  // at by anything.
  //
  // Everything else is still stored, because storage is free and the record
  // keeps dedupe exact and feeds chat context. It just skips the AI call.
  const stored = [];
  let enrichedCount = 0;

  for (const article of processed) {
    try {
      const shouldEnrich = article.priority === 'high' && enrichedCount < AI_ENRICH_LIMIT;
      const enrichment = shouldEnrich ? await enrich(article) : {};
      if (shouldEnrich) enrichedCount += 1;

      const doc = await save(article, enrichment);
      stored.push({ ...doc, id: article.headlineHash });
    } catch (err) {
      monitoring.logApiFailure('pipeline:save', err.message);
    }
  }

  const stats = {
    provider: providerName,
    fetched: raw.length,
    afterDedupe: processed.length,
    enriched: stored.length,
    ms: Date.now() - started,
  };
  monitoring.logPipelineRun(stats);

  return { stored, ...stats };
}

module.exports = { run, enrich, loadSeenHashes };

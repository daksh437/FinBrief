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

async function loadSeenHashes(limit = 200) {
  try {
    const snap = await db.collection('news').orderBy('processedAt', 'desc').limit(limit).get();
    return new Set(snap.docs.map((d) => d.data().headlineHash).filter(Boolean));
  } catch (err) {
    monitoring.logApiFailure('firestore:news', err.message);
    return new Set();
  }
}

/// Runs the full AI pipeline for one article (v12 §4).
async function enrich(article) {
  const source = article.summary || article.title;
  const result = {
    aiSummary: null,
    hindiSummary: null,
    keyPoints: [],
    impact: null,
    followUpQuestions: [],
  };

  try {
    const structured = await gemini.summarizeStructured(source);
    result.aiSummary = structured.summary;
    result.keyPoints = structured.keyPoints;
  } catch (err) {
    monitoring.logAiFailure('summary', err.message);
  }

  try {
    result.hindiSummary = await gemini.translateToHindi(result.aiSummary || source);
  } catch (err) {
    monitoring.logAiFailure('translate', err.message);
  }

  try {
    result.impact = await gemini.analyzeImpact(source);
  } catch (err) {
    monitoring.logAiFailure('impact', err.message);
  }

  // Suggested follow-ups are derived locally rather than via another Gemini
  // call — a 4th AI request per article isn't worth the cost/latency.
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

  const seen = await loadSeenHashes();
  const processed = processor.process(raw, seen);

  const stored = [];
  for (const article of processed.slice(0, AI_ENRICH_LIMIT)) {
    try {
      const enrichment = await enrich(article);
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

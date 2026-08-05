const fetch = require('node-fetch');
const newsCache = require('./newsCacheService');
const newsProviders = require('./newsProviders');
const newsArchive = require('./newsArchiveService');

const NEWS_API_KEY = process.env.NEWS_API_KEY;
const NEWS_API_BASE = process.env.NEWS_API_BASE || 'https://newsapi.org/v2';

// Always false in practice: the RSS provider needs no key and is always
// available, so the app never falls back to sample articles.
const MOCK_MODE = !newsProviders.activeProvider();

const MOCK_ARTICLES = [
  {
    id: 'mock-1',
    title: 'Sensex climbs 400 points as IT stocks rally',
    source: 'Mock Financial Times',
    url: 'https://example.com/mock-1',
    publishedAt: new Date().toISOString(),
    summary: 'Mock article — set NEWS_API_KEY for real data.',
  },
  {
    id: 'mock-2',
    title: 'RBI holds repo rate steady at 6.5%',
    source: 'Mock Economic Times',
    url: 'https://example.com/mock-2',
    publishedAt: new Date().toISOString(),
    summary: 'Mock article — set NEWS_API_KEY for real data.',
  },
];

function normalize(article, i) {
  return {
    id: article.url || `article-${i}`,
    title: article.title,
    source: article.source && article.source.name,
    url: article.url,
    publishedAt: article.publishedAt,
    summary: article.description || null,
    imageUrl: article.urlToImage || null,
  };
}

// RSS feeds have no page parameter — they hand back the latest N items. So we
// fetch one large pool per category, cache it, and paginate by slicing.
// (Before this, `page` was part of the cache key but was never passed to the
// provider, so "Load more" re-fetched the same top-N and showed duplicates.)
const POOL_SIZE = 150;

/// Several feeds carry the same story (e.g. ET's own feed and Google News),
/// so drop repeats by URL and by normalized headline before paginating.
function dedupe(articles = []) {
  const seen = new Set();
  return articles.filter((a) => {
    const key = (a.url || '') + '|' + String(a.title || '').toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

async function getFeed({ category = 'business', country = 'in', page = 1, pageSize = 20 } = {}) {
  if (MOCK_MODE) return MOCK_ARTICLES;

  const cacheKey = `feed_${country}_${category}`;
  let pool = await newsCache.get(cacheKey);

  if (!pool) {
    // Provider registry (RSS primary, NewsAPI optional) before any direct call.
    const fromProvider = await newsProviders.fetchNews({ category, limit: POOL_SIZE });
    if (fromProvider) {
      pool = dedupe(fromProvider.articles);
      await newsCache.set(cacheKey, pool);
      // Fire-and-forget: builds the archive that serves pages past the pool.
      newsArchive.archive(pool, category);
    }
  }

  if (pool) {
    const start = (page - 1) * pageSize;
    const slice = pool.slice(start, start + pageSize);
    if (slice.length) return slice;

    // Past the live RSS window — continue from the archive so users can keep
    // scrolling into older news instead of hitting a dead end.
    const oldest = pool[pool.length - 1];
    return dedupe(
      await newsArchive.older({
        category,
        beforeMs: oldest ? Date.parse(oldest.publishedAt) || undefined : undefined,
        limit: pageSize,
      })
    );
  }

  const url = `${NEWS_API_BASE}/top-headlines?category=${category}&country=${country}&page=${page}&pageSize=${pageSize}&apiKey=${NEWS_API_KEY}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`News API error: ${res.status}`);
  const json = await res.json();
  const articles = (json.articles || []).map(normalize);

  await newsCache.set(cacheKey, articles);
  return articles;
}

// Latest headlines regardless of category — what the Home screen's breaking
// banner and the notification cron both consume.
async function getBreaking({ country = 'in', pageSize = 10 } = {}) {
  if (MOCK_MODE) return MOCK_ARTICLES;

  const cacheKey = `breaking_${country}_${pageSize}`;
  const cached = await newsCache.get(cacheKey);
  if (cached) return cached;

  const fromProvider = await newsProviders.fetchNews({ limit: pageSize });
  if (fromProvider) {
    await newsCache.set(cacheKey, fromProvider.articles);
    return fromProvider.articles;
  }

  const url = `${NEWS_API_BASE}/top-headlines?country=${country}&pageSize=${pageSize}&apiKey=${NEWS_API_KEY}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`News API error: ${res.status}`);
  const json = await res.json();
  const articles = (json.articles || []).map(normalize);

  await newsCache.set(cacheKey, articles);
  return articles;
}

async function search(query, { page = 1, pageSize = 20 } = {}) {
  if (MOCK_MODE) {
    return MOCK_ARTICLES.filter((a) => a.title.toLowerCase().includes(query.toLowerCase()));
  }

  const fromProvider = await newsProviders.searchNews(query, { limit: pageSize });
  if (fromProvider) return fromProvider.articles;

  const url = `${NEWS_API_BASE}/everything?q=${encodeURIComponent(query)}&sortBy=publishedAt&page=${page}&pageSize=${pageSize}&apiKey=${NEWS_API_KEY}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`News API error: ${res.status}`);
  const json = await res.json();
  return (json.articles || []).map(normalize);
}

// Static for now — replace with real search-analytics-driven trending terms later.
function getTrendingSearches() {
  return ['Sensex', 'Nifty 50', 'Bitcoin', 'Gold Rate', 'IPO', 'RBI Repo Rate', 'USD INR'];
}

module.exports = { getFeed, getBreaking, search, getTrendingSearches, MOCK_MODE };

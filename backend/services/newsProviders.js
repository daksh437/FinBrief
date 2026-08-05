const fetch = require('node-fetch');
const { rss } = require('./rssProvider');

// News provider registry.
//
// RSS is the primary (and only always-available) provider: it needs no key,
// has no daily quota, and — verified against Indian publisher feeds — carries
// the descriptions and images that a paid aggregator was supplying. NewsAPI
// is kept purely as an optional extra if someone sets a key; MarketAux was
// removed after confirming RSS matched it on content while removing both the
// cost and the 100-requests/day polling ceiling.
//
// Every provider returns the same normalized article shape:
//   { id, title, source, url, publishedAt, summary, imageUrl }

const NEWS_API_KEY = process.env.NEWS_API_KEY;
const TIMEOUT_MS = 10_000;

async function fetchJson(url) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const res = await fetch(url, { signal: controller.signal });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } finally {
    clearTimeout(timer);
  }
}

const newsapi = {
  name: 'newsapi',
  get available() {
    return Boolean(NEWS_API_KEY);
  },
  async fetchNews({ category = 'business', limit = 20 } = {}) {
    const base = process.env.NEWS_API_BASE || 'https://newsapi.org/v2';
    const json = await fetchJson(
      `${base}/top-headlines?category=${category}&country=in&pageSize=${limit}&apiKey=${NEWS_API_KEY}`
    );
    return (json.articles || []).map((a, i) => ({
      id: a.url || `article-${i}`,
      title: a.title,
      source: a.source?.name,
      url: a.url,
      publishedAt: a.publishedAt,
      summary: a.description || null,
      imageUrl: a.urlToImage || null,
    }));
  },
};

// Order = priority. RSS first because it's free, unmetered and rich.
const PROVIDERS = [rss, newsapi];

function activeProvider() {
  return PROVIDERS.find((p) => p.available) || null;
}

/// Tries providers in order; returns null only if every one fails.
async function fetchNews(options = {}) {
  for (const provider of PROVIDERS) {
    if (!provider.available) continue;
    try {
      const articles = await provider.fetchNews(options);
      if (articles.length) return { provider: provider.name, articles };
    } catch (err) {
      console.error(`[newsProviders] ${provider.name} failed:`, err.message);
    }
  }
  return null;
}

async function searchNews(query, options = {}) {
  for (const provider of PROVIDERS) {
    if (!provider.available || typeof provider.search !== 'function') continue;
    try {
      const articles = await provider.search(query, options);
      if (articles.length) return { provider: provider.name, articles };
    } catch (err) {
      console.error(`[newsProviders] ${provider.name} search failed:`, err.message);
    }
  }
  return null;
}

module.exports = { fetchNews, searchNews, activeProvider, PROVIDERS };

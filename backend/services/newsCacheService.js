const { db } = require('../config/firebaseAdmin');

const TTL_MS = Number(process.env.NEWS_CACHE_TTL_MS || 5 * 60 * 1000);

// Server-side news cache (v11 `news_cache`) — cuts repeat upstream News API
// calls, which matters because that quota is the main cost driver and the
// "API pricing" risk called out back in the original BRD.
//
// Every failure path degrades to a cache miss rather than throwing, so a
// Firestore hiccup can never take down the news feed itself.
async function get(key) {
  try {
    const doc = await db.collection('news_cache').doc(key).get();
    if (!doc.exists) return null;

    const { articles, cachedAt } = doc.data();
    if (!cachedAt || Date.now() - cachedAt > TTL_MS) return null;
    return articles;
  } catch (err) {
    console.error('[news_cache] read failed:', err.message);
    return null;
  }
}

async function set(key, articles) {
  if (!Array.isArray(articles) || articles.length === 0) return;
  try {
    await db.collection('news_cache').doc(key).set({ articles, cachedAt: Date.now() });
  } catch (err) {
    console.error('[news_cache] write failed:', err.message);
  }
}

module.exports = { get, set, TTL_MS };

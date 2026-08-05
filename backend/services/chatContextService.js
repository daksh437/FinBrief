const { db } = require('../config/firebaseAdmin');
const marketService = require('./marketService');

// Builds the context block injected into AI chat (v13 §7): latest news, the
// user's bookmarks and a market snapshot.
//
// Every section is best-effort — if any lookup fails we simply omit it rather
// than failing the chat request. Returns null when nothing is available, in
// which case chat runs without context.
const MAX_NEWS = 5;
const MAX_BOOKMARKS = 5;

async function recentNews() {
  try {
    const snap = await db.collection('news').orderBy('processedAt', 'desc').limit(MAX_NEWS).get();
    return snap.docs.map((d) => {
      const n = d.data();
      return `- ${n.headline}${n.aiSummary ? ` — ${n.aiSummary}` : ''}`;
    });
  } catch {
    return [];
  }
}

async function userBookmarks(uid) {
  try {
    const snap = await db
      .collection('users')
      .doc(uid)
      .collection('bookmarks')
      .orderBy('savedAt', 'desc')
      .limit(MAX_BOOKMARKS)
      .get();
    return snap.docs.map((d) => `- ${d.data().title}`);
  } catch {
    return [];
  }
}

async function marketSnapshot() {
  try {
    const overview = await marketService.getOverviewLive();
    const fmt = (items) =>
      (items || []).map((i) => `${i.name}: ${i.value} (${i.changePercent >= 0 ? '+' : ''}${i.changePercent}%)`);
    return [...fmt(overview.indices), ...fmt(overview.crypto), ...fmt(overview.gold)];
  } catch {
    return [];
  }
}

/// Assembles the context string for a given user. Returns null if empty.
async function build(uid) {
  const [news, bookmarks, market] = await Promise.all([
    recentNews(),
    uid ? userBookmarks(uid) : Promise.resolve([]),
    marketSnapshot(),
  ]);

  const sections = [];
  if (market.length) sections.push(`Current market data:\n${market.join('\n')}`);
  if (news.length) sections.push(`Latest news:\n${news.join('\n')}`);
  if (bookmarks.length) sections.push(`Articles this user bookmarked:\n${bookmarks.join('\n')}`);

  return sections.length ? sections.join('\n\n') : null;
}

module.exports = { build, recentNews, userBookmarks, marketSnapshot };

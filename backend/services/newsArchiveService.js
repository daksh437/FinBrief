const crypto = require('crypto');
const { db } = require('../config/firebaseAdmin');

// Long-term news archive.
//
// Why this exists: RSS feeds only hand back the publisher's latest items
// (~150 articles, roughly a day or two). Once a user scrolls past that, there
// is nothing left to serve. So every article the live feed fetches is written
// here, and older pages are answered from Firestore instead of RSS. The
// archive grows on its own as the app is used — no extra API cost.
//
// Writes are fire-and-forget: archiving must never slow down or fail a feed
// request. Reads return [] on any error so the caller just shows "no more".
const COLLECTION = 'news_archive';
const RETENTION_DAYS = 30;

const docId = (article) =>
  crypto.createHash('sha1').update(article.url || article.title || '').digest('hex').slice(0, 24);

const millis = (value) => {
  const t = Date.parse(value);
  return Number.isNaN(t) ? Date.now() : t;
};

// Ids written since this process started. Feeds re-serve the same articles for
// hours, so without this the refresh cron would rewrite ~150 documents every
// run — roughly 20k writes/day, which is the entire Firestore free-tier daily
// write budget spent on data that never changed. Bounded and rebuilt on
// restart, which at worst costs one redundant batch.
const written = new Set();
const MAX_TRACKED = 20_000;

/// Stores articles, skipping ones already archived. Never throws.
async function archive(articles = [], category = 'business') {
  if (!articles.length) return 0;

  const fresh = articles.filter((a) => a.title && !written.has(docId(a)));
  if (!fresh.length) return 0;

  try {
    // Firestore batches cap at 500 writes; feed pools are ~150 so one is enough.
    const batch = db.batch();
    for (const article of fresh.slice(0, 400)) {
      batch.set(
        db.collection(COLLECTION).doc(docId(article)),
        {
          ...article,
          category,
          publishedAtMs: millis(article.publishedAt),
          archivedAt: Date.now(),
        },
        { merge: true }
      );
    }
    await batch.commit();

    if (written.size > MAX_TRACKED) written.clear();
    fresh.forEach((a) => written.add(docId(a)));
    return fresh.length;
  } catch (err) {
    console.error('[newsArchive] write failed:', err.message);
    return 0;
  }
}

const strip = (doc) => {
  const { publishedAtMs, archivedAt, ...article } = doc.data();
  return article;
};

/// Articles older than `beforeMs`, newest first. Used to continue paginating
/// once the live RSS pool is exhausted.
///
/// The fast path (category filter + sort) needs a composite index. Creating
/// that index requires console access the backend service account doesn't
/// have, so when it's missing we fall back to a sort-only query — which
/// Firestore indexes automatically — and filter by category in memory.
/// Over-fetching a few pages costs little at this scale and means the archive
/// works immediately, with or without the index deployed.
async function older({ category = 'business', beforeMs, limit = 20 } = {}) {
  const paginate = (q) => (beforeMs ? q.startAfter(beforeMs) : q);

  try {
    const snap = await paginate(
      db.collection(COLLECTION).where('category', '==', category).orderBy('publishedAtMs', 'desc').limit(limit)
    ).get();
    return snap.docs.map(strip);
  } catch (err) {
    if (err.code !== 9 && !/requires an index/i.test(err.message || '')) {
      console.error('[newsArchive] read failed:', err.message);
      return [];
    }
  }

  try {
    const snap = await paginate(
      db.collection(COLLECTION).orderBy('publishedAtMs', 'desc').limit(limit * 8)
    ).get();
    return snap.docs
      .filter((d) => d.get('category') === category)
      .slice(0, limit)
      .map(strip);
  } catch (err) {
    console.error('[newsArchive] fallback read failed:', err.message);
    return [];
  }
}

/// Drops articles past the retention window. Called by the cleanup cron.
async function prune() {
  try {
    const cutoff = Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000;
    const snap = await db.collection(COLLECTION).where('publishedAtMs', '<', cutoff).limit(400).get();
    if (snap.empty) return 0;

    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    return snap.size;
  } catch (err) {
    console.error('[newsArchive] prune failed:', err.message);
    return 0;
  }
}

module.exports = { archive, older, prune, COLLECTION, RETENTION_DAYS };

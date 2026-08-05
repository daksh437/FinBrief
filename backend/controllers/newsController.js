const newsService = require('../services/newsService');
const { db } = require('../config/firebaseAdmin');

async function feed(req, res) {
  const { category, page, pageSize } = req.query;
  const articles = await newsService.getFeed({ category, page: Number(page) || 1, pageSize: Number(pageSize) || 20 });
  res.json({ success: true, data: articles, fallback: newsService.MOCK_MODE });
}

async function breaking(req, res) {
  const articles = await newsService.getBreaking({ pageSize: Number(req.query.pageSize) || 10 });
  res.json({ success: true, data: articles, fallback: newsService.MOCK_MODE });
}

async function trendingSearches(req, res) {
  res.json({ success: true, data: newsService.getTrendingSearches() });
}

async function search(req, res) {
  const { q, page, pageSize } = req.query;
  if (!q) return res.status(400).json({ success: false, error: 'q is required' });

  const articles = await newsService.search(q, { page: Number(page) || 1, pageSize: Number(pageSize) || 20 });
  res.json({ success: true, data: articles, fallback: newsService.MOCK_MODE });
}

async function listBookmarks(req, res) {
  const snap = await db.collection('users').doc(req.user.uid).collection('bookmarks').orderBy('savedAt', 'desc').get();
  const bookmarks = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  res.json({ success: true, data: bookmarks });
}

async function addBookmark(req, res) {
  const { article } = req.body;
  if (!article || !article.id) return res.status(400).json({ success: false, error: 'article with id is required' });

  await db
    .collection('users')
    .doc(req.user.uid)
    .collection('bookmarks')
    .doc(article.id)
    .set({ ...article, savedAt: Date.now() });

  res.json({ success: true, data: { id: article.id } });
}

async function removeBookmark(req, res) {
  const { id } = req.params;
  await db.collection('users').doc(req.user.uid).collection('bookmarks').doc(id).delete();
  res.json({ success: true, data: { id } });
}

module.exports = { feed, breaking, search, trendingSearches, listBookmarks, addBookmark, removeBookmark };

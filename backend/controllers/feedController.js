const { db } = require('../config/firebaseAdmin');
const newsService = require('../services/newsService');
const processor = require('../services/newsProcessor');

// Personalised feed — the thing a broadcast squawk service structurally
// cannot do, because it doesn't know what the user owns.
//
// Matches processed news against the user's portfolio + watchlist symbols and
// their chosen interest categories, and explains WHY each item was surfaced.

// Sector keywords let us match holdings even when the article never names the
// company (e.g. an RBI story matters to a bank holding).
const SECTOR_HINTS = {
  HDFCBANK: ['bank', 'banking', 'rbi', 'repo', 'lending', 'nbfc'],
  ICICIBANK: ['bank', 'banking', 'rbi', 'repo', 'lending'],
  SBIN: ['bank', 'banking', 'rbi', 'repo', 'psu bank'],
  TCS: ['it ', 'software', 'tech', 'nasscom', 'outsourcing'],
  INFY: ['it ', 'software', 'tech', 'nasscom', 'outsourcing'],
  WIPRO: ['it ', 'software', 'tech'],
  RELIANCE: ['reliance', 'oil', 'refining', 'telecom', 'retail'],
  BTC: ['bitcoin', 'crypto'],
  ETH: ['ethereum', 'crypto'],
};

async function userSymbols(uid) {
  const [portfolio, watchlist] = await Promise.all([
    db.collection('users').doc(uid).collection('portfolio').get().catch(() => null),
    db.collection('users').doc(uid).collection('watchlist').get().catch(() => null),
  ]);

  const symbols = new Set();
  portfolio?.docs.forEach((d) => symbols.add(String(d.data().symbol || d.id).toUpperCase()));
  watchlist?.docs.forEach((d) => symbols.add(String(d.data().symbol || d.id).toUpperCase()));
  return [...symbols];
}

/// Returns the reasons an article is relevant to this user, or [] if it isn't.
function relevanceFor(article, symbols) {
  const haystack = `${article.title || ''} ${article.summary || ''}`.toLowerCase();
  const reasons = [];

  for (const symbol of symbols) {
    // Direct hit: the processor already tagged this ticker.
    if ((article.tags || []).includes(symbol)) {
      reasons.push({ symbol, why: 'mentioned' });
      continue;
    }
    // Indirect: sector keywords that affect this holding.
    const hints = SECTOR_HINTS[symbol] || [];
    if (hints.some((h) => haystack.includes(h))) {
      reasons.push({ symbol, why: 'sector' });
    }
  }
  return reasons;
}

async function personalised(req, res) {
  const symbols = await userSymbols(req.user.uid);

  if (!symbols.length) {
    return res.json({
      success: true,
      data: { articles: [], symbols: [] },
      message: 'Add holdings to your portfolio or watchlist to get personalised news.',
    });
  }

  const raw = await newsService.getFeed({ pageSize: 30 });
  const processed = processor.process(raw);

  const matched = processed
    .map((article) => ({ article, reasons: relevanceFor(article, symbols) }))
    .filter((m) => m.reasons.length > 0)
    // Direct mentions rank above sector-level matches.
    .sort((a, b) => {
      const score = (m) => m.reasons.filter((r) => r.why === 'mentioned').length * 10 + m.reasons.length;
      return score(b) - score(a);
    })
    .slice(0, 20)
    .map(({ article, reasons }) => ({
      ...article,
      relevance: {
        symbols: reasons.map((r) => r.symbol),
        direct: reasons.some((r) => r.why === 'mentioned'),
        // Human-readable line the app shows under the headline.
        label:
          reasons.length === 1
            ? `Affects your ${reasons[0].symbol}`
            : `Affects ${reasons.length} of your holdings`,
      },
    }));

  res.json({ success: true, data: { articles: matched, symbols }, fallback: newsService.MOCK_MODE });
}

module.exports = { personalised, relevanceFor, userSymbols };

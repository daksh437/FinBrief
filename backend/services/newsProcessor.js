const crypto = require('crypto');

// Pure news-processing logic (v12 §5). No I/O here on purpose so this is
// cheap to unit-test and safe to reuse from any job or route.

const CATEGORY_KEYWORDS = {
  Crypto: ['bitcoin', 'btc', 'ethereum', 'eth', 'crypto', 'blockchain', 'token', 'altcoin'],
  Gold: ['gold', 'silver', 'bullion', 'precious metal'],
  Forex: ['rupee', 'usd', 'inr', 'forex', 'currency', 'dollar', 'exchange rate'],
  IPO: ['ipo', 'listing', 'public issue', 'subscription', 'grey market'],
  Economy: ['gdp', 'inflation', 'rbi', 'repo rate', 'fiscal', 'monetary', 'cpi', 'unemployment'],
  Stocks: ['sensex', 'nifty', 'stock', 'shares', 'equity', 'bse', 'nse', 'earnings', 'quarterly'],
};

// Words that suggest a genuinely market-moving story rather than routine news.
const HIGH_PRIORITY_KEYWORDS = [
  'breaking', 'crash', 'plunge', 'surge', 'record high', 'record low', 'halt',
  'emergency', 'default', 'bankruptcy', 'rate cut', 'rate hike', 'ban', 'fraud',
];

const COMPANY_TICKERS = {
  reliance: 'RELIANCE', tcs: 'TCS', infosys: 'INFY', hdfc: 'HDFCBANK',
  icici: 'ICICIBANK', adani: 'ADANIENT', wipro: 'WIPRO', airtel: 'BHARTIARTL',
  sbi: 'SBIN', bitcoin: 'BTC', ethereum: 'ETH',
};

/// Normalises a headline so trivial punctuation/case/spacing differences
/// between sources collapse to the same fingerprint.
function normalizeHeadline(title) {
  return String(title || '')
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function headlineHash(title) {
  return crypto.createHash('sha1').update(normalizeHeadline(title)).digest('hex');
}

function classifyCategory(article) {
  const haystack = `${article.title || ''} ${article.summary || ''}`.toLowerCase();
  for (const [category, words] of Object.entries(CATEGORY_KEYWORDS)) {
    if (words.some((w) => haystack.includes(w))) return category;
  }
  return 'Business';
}

function extractTags(article) {
  const haystack = `${article.title || ''} ${article.summary || ''}`.toLowerCase();
  const tags = new Set();
  for (const [name, ticker] of Object.entries(COMPANY_TICKERS)) {
    if (haystack.includes(name)) tags.add(ticker);
  }
  return [...tags];
}

/// 'high' articles are pushed instantly; everything else is batched into the
/// morning/evening briefs (v12 §7).
function assignPriority(article) {
  const haystack = `${article.title || ''} ${article.summary || ''}`.toLowerCase();
  if (HIGH_PRIORITY_KEYWORDS.some((w) => haystack.includes(w))) return 'high';

  const publishedAt = Date.parse(article.publishedAt || '');
  const isRecent = Number.isFinite(publishedAt) && Date.now() - publishedAt < 60 * 60 * 1000;
  return isRecent ? 'medium' : 'low';
}

/// Removes articles whose normalized headline was already seen — both within
/// this batch and against previously-processed hashes.
function dedupe(articles, seenHashes = new Set()) {
  const out = [];
  const batchHashes = new Set();

  for (const article of articles) {
    const hash = headlineHash(article.title);
    if (!hash || seenHashes.has(hash) || batchHashes.has(hash)) continue;
    batchHashes.add(hash);
    out.push({ ...article, headlineHash: hash });
  }
  return out;
}

/// dedupe + classify + tag + prioritise, sorted most important first.
function process(articles, seenHashes = new Set()) {
  const priorityRank = { high: 0, medium: 1, low: 2 };

  return dedupe(articles, seenHashes)
    .map((article) => ({
      ...article,
      category: classifyCategory(article),
      tags: extractTags(article),
      priority: assignPriority(article),
    }))
    .sort((a, b) => priorityRank[a.priority] - priorityRank[b.priority]);
}

module.exports = {
  normalizeHeadline,
  headlineHash,
  classifyCategory,
  extractTags,
  assignPriority,
  dedupe,
  process,
};

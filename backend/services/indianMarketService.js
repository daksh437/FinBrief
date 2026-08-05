const fetch = require('node-fetch');

// Free Indian market data — indices via Yahoo Finance, forex via Frankfurter
// (ECB reference rates). Neither needs an API key.
//
// TRADE-OFF, stated plainly: Yahoo's chart endpoint is a public endpoint, not
// a documented/supported API. It's widely used and works today (verified), but
// Yahoo can change or throttle it without notice. That's the cost of avoiding
// a paid provider — every paid option checked put Indian indices behind a
// subscription (Finnhub's free tier returns "subscription required" for these).
// Every function here returns null on failure so callers fall back to mock
// values rather than the Home screen breaking.
const TIMEOUT_MS = 10_000;
const CACHE_TTL_MS = 60_000;

const INDICES = [
  { symbol: '^BSESN', display: 'SENSEX', name: 'BSE Sensex' },
  { symbol: '^NSEI', display: 'NIFTY', name: 'Nifty 50' },
];

const GOLD = [{ symbol: 'GC=F', display: 'XAU', name: 'Gold (USD/oz)' }];

const cache = new Map();

function cached(key) {
  const hit = cache.get(key);
  return hit && Date.now() - hit.at < CACHE_TTL_MS ? hit.data : null;
}

async function fetchJson(url) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const res = await fetch(url, {
      signal: controller.signal,
      // Yahoo rejects requests without a browser-like UA.
      headers: { 'User-Agent': 'Mozilla/5.0 (compatible; FinBrief/1.0)' },
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } finally {
    clearTimeout(timer);
  }
}

async function quote({ symbol, display, name }) {
  const json = await fetchJson(
    `https://query1.finance.yahoo.com/v8/finance/chart/${encodeURIComponent(symbol)}`
  );
  const meta = json?.chart?.result?.[0]?.meta;
  if (!meta?.regularMarketPrice) return null;

  const price = meta.regularMarketPrice;
  const prev = meta.chartPreviousClose ?? meta.previousClose ?? price;
  const changePercent = prev ? ((price - prev) / prev) * 100 : 0;

  return {
    symbol: display,
    name,
    value: Number(price.toFixed(2)),
    changePercent: Number(changePercent.toFixed(2)),
  };
}

/// Fetches a cached group of Yahoo quotes. Exported so other services (e.g.
/// global/US equities) can reuse the same free source instead of adding
/// another paid provider. Returns null if every symbol fails.
async function fetchQuotes(key, defs) {
  const hit = cached(key);
  if (hit) return hit;

  try {
    const results = await Promise.all(defs.map((d) => quote(d).catch(() => null)));
    const items = results.filter(Boolean);
    if (!items.length) return null;

    cache.set(key, { at: Date.now(), data: items });
    return items;
  } catch (err) {
    console.error(`[yahoo] ${key} failed:`, err.message);
    return null;
  }
}

const getIndices = () => fetchQuotes('indices', INDICES);
const getGold = () => fetchQuotes('gold', GOLD);

/// USD/INR via Frankfurter (free, no key, ECB data).
/// Note: Frankfurter publishes daily reference rates, so this is not intraday.
async function getForex() {
  const hit = cached('forex');
  if (hit) return hit;

  try {
    const json = await fetchJson('https://api.frankfurter.app/latest?from=USD&to=INR');
    const rate = json?.rates?.INR;
    if (!rate) return null;

    const items = [{ symbol: 'USDINR', name: 'USD/INR', value: Number(rate.toFixed(2)), changePercent: 0 }];
    cache.set('forex', { at: Date.now(), data: items });
    return items;
  } catch (err) {
    console.error('[frankfurter] forex failed:', err.message);
    return null;
  }
}

module.exports = { getIndices, getGold, getForex, fetchQuotes, INDICES };

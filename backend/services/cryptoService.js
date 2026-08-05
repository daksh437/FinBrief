const fetch = require('node-fetch');

// CoinGecko's public API needs no key (v12 §2). This is the one live data
// source in the stack today — everything else is still mock until keys exist.
// Any failure degrades to null so callers can fall back to mock prices rather
// than the whole market endpoint failing.
const BASE = 'https://api.coingecko.com/api/v3';
const COINS = { bitcoin: 'BTC', ethereum: 'ETH' };
const TIMEOUT_MS = 8000;

let cache = { at: 0, data: null };
const CACHE_TTL_MS = 60_000;

async function getPrices() {
  if (cache.data && Date.now() - cache.at < CACHE_TTL_MS) return cache.data;

  const ids = Object.keys(COINS).join(',');
  const url = `${BASE}/simple/price?ids=${ids}&vs_currencies=usd&include_24hr_change=true`;

  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
    const res = await fetch(url, { signal: controller.signal });
    clearTimeout(timer);

    if (!res.ok) throw new Error(`CoinGecko ${res.status}`);
    const json = await res.json();

    const items = Object.entries(COINS)
      .filter(([id]) => json[id])
      .map(([id, symbol]) => ({
        symbol,
        name: id.charAt(0).toUpperCase() + id.slice(1),
        value: Number(json[id].usd),
        changePercent: Number((json[id].usd_24h_change ?? 0).toFixed(2)),
      }));

    if (!items.length) throw new Error('CoinGecko returned no usable prices');

    cache = { at: Date.now(), data: items };
    return items;
  } catch (err) {
    console.error('[coingecko] fetch failed:', err.message);
    return null;
  }
}

module.exports = { getPrices };

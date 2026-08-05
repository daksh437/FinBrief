// Indices / gold / forex / IPO are still mock data so the Home screen has
// something realistic to render — swap in a real provider when keys exist.
// Crypto IS live via CoinGecko (see getOverviewLive below).
const cryptoService = require('./cryptoService');
const globalMarketService = require('./globalMarketService');
const indianMarketService = require('./indianMarketService');

function jitter(base, pct = 2) {
  const delta = base * (pct / 100) * (Math.random() * 2 - 1);
  return Number((base + delta).toFixed(2));
}

function getIndices() {
  return [
    { symbol: 'SENSEX', name: 'BSE Sensex', value: jitter(81000), changePercent: jitter(0.4, 300) },
    { symbol: 'NIFTY', name: 'Nifty 50', value: jitter(24700), changePercent: jitter(0.3, 300) },
  ];
}

function getCrypto() {
  return [
    { symbol: 'BTC', name: 'Bitcoin', value: jitter(64000), changePercent: jitter(1.2, 300) },
    { symbol: 'ETH', name: 'Ethereum', value: jitter(3400), changePercent: jitter(1.5, 300) },
  ];
}

function getGold() {
  return [{ symbol: 'XAU', name: 'Gold (10g)', value: jitter(72000), changePercent: jitter(0.2, 300) }];
}

function getForex() {
  return [{ symbol: 'USDINR', name: 'USD/INR', value: jitter(83.3, 0.5), changePercent: jitter(0.1, 300) }];
}

function getIpoCalendar() {
  return [
    { company: 'Mock Tech Ltd', openDate: '2026-08-10', closeDate: '2026-08-12', priceRange: '₹210-220' },
    { company: 'Sample Finance Corp', openDate: '2026-08-18', closeDate: '2026-08-20', priceRange: '₹95-100' },
  ];
}

const INSIGHTS = [
  'Nifty likely to stay range-bound today amid mixed global cues.',
  'IT stocks in focus after strong Q1 earnings from major exporters.',
  'Gold holds steady as investors weigh rate-cut expectations.',
  'Rupee under mild pressure against the dollar on crude oil prices.',
  'Banking stocks lead gains on stable asset-quality outlook.',
];

// Canned "AI insight of the day" — free and unlimited (no aiAccess gate, no
// Gemini call), unlike the real per-article AI features under /ai/*.
function getInsight() {
  const insight = INSIGHTS[Math.floor(Math.random() * INSIGHTS.length)];
  return { insight, generatedAt: new Date().toISOString() };
}

const AI_PICKS_POOL = [
  { symbol: 'INFY', name: 'Infosys', sentiment: 'bullish', reason: 'Strong deal pipeline and margin expansion in IT services.' },
  { symbol: 'HDFCBANK', name: 'HDFC Bank', sentiment: 'bullish', reason: 'Stable asset quality and steady credit growth.' },
  { symbol: 'BTC', name: 'Bitcoin', sentiment: 'neutral', reason: 'Consolidating after recent rally; awaiting fresh catalysts.' },
  { symbol: 'XAU', name: 'Gold', sentiment: 'bullish', reason: 'Safe-haven demand steady amid global uncertainty.' },
  { symbol: 'RELIANCE', name: 'Reliance Industries', sentiment: 'neutral', reason: 'Retail and telecom growth offset by refining margin pressure.' },
];

// Canned "AI Picks" — same idea as getInsight(): free/unlimited, no Gemini
// call, no aiAccess credit cost. Replace with a real model-driven picks
// pipeline later.
function getAiPicks() {
  const shuffled = [...AI_PICKS_POOL].sort(() => Math.random() - 0.5);
  return shuffled.slice(0, 3);
}

// Deterministic-ish mock quote per symbol (same symbol -> same rough base
// price within a session, since jitter() reseeds each call) — good enough
// for portfolio P/L display without a real market-data provider.
function getQuotes(symbols) {
  return symbols.map((symbol) => {
    let hash = 0;
    for (const char of symbol) hash = (hash * 31 + char.charCodeAt(0)) % 100000;
    const base = 50 + (hash % 4950);
    return { symbol, price: jitter(base, 3), changePercent: jitter(0.5, 400) };
  });
}

// Crypto is the one section backed by a real provider (CoinGecko, no API key
// needed). Falls back to the mock values if the request fails so the Home
// screen never loses the section entirely.
async function getOverviewLive() {
  const overview = getOverview();

  // Each source is independent; a failure just leaves that section on mock.
  const [liveCrypto, globalStocks, indices, gold, forex] = await Promise.all([
    cryptoService.getPrices(),
    globalMarketService.getGlobalStocks(),
    indianMarketService.getIndices(),
    indianMarketService.getGold(),
    indianMarketService.getForex(),
  ]);

  return {
    ...overview,
    indices: indices || overview.indices,
    crypto: liveCrypto || overview.crypto,
    gold: gold || overview.gold,
    forex: forex || overview.forex,
    // Empty array if the upstream fetch fails — the client hides the
    // section rather than showing a fake one.
    globalMarkets: globalStocks,
  };
}

function getOverview() {
  return {
    indices: getIndices(),
    crypto: getCrypto(),
    gold: getGold(),
    forex: getForex(),
    ipoCalendar: getIpoCalendar(),
  };
}

module.exports = { getOverview, getOverviewLive, getInsight, getAiPicks, getQuotes };

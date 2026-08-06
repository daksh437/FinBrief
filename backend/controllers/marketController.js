const marketService = require('../services/marketService');
const indianMarketService = require('../services/indianMarketService');

async function overview(req, res) {
  // Indices, gold, forex and global equities come from Yahoo and crypto from
  // CoinGecko — all live. The IPO calendar is the one remaining mock section.
  const data = await marketService.getOverviewLive();
  res.json({ success: true, data, fallback: true });
}

// Both sections are generated from the day's real headlines. On failure they
// return null/[] and the client hides the section — better than showing
// invented analysis under an "AI" label.
async function insight(req, res) {
  const data = await marketService.getDailyBrief();
  res.json({ success: true, data, fallback: false });
}

async function aiPicks(req, res) {
  const data = await marketService.getInFocus();
  res.json({ success: true, data, fallback: false });
}

async function quotes(req, res) {
  const symbols = String(req.query.symbols || '')
    .split(',')
    .map((s) => s.trim().toUpperCase())
    .filter(Boolean);

  if (!symbols.length) return res.status(400).json({ success: false, error: 'symbols query param is required' });

  // Real prices only. Unresolvable symbols are left out entirely — a portfolio
  // screen showing an invented price is worse than one showing no price.
  const data = await indianMarketService.getLiveQuotes(symbols);
  res.json({ success: true, data, fallback: false });
}

module.exports = { overview, insight, aiPicks, quotes };

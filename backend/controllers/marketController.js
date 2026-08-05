const marketService = require('../services/marketService');

async function overview(req, res) {
  // Crypto comes from CoinGecko (live); the rest is still mock, hence
  // fallback stays true.
  const data = await marketService.getOverviewLive();
  res.json({ success: true, data, fallback: true });
}

async function insight(req, res) {
  res.json({ success: true, data: marketService.getInsight(), fallback: true });
}

async function aiPicks(req, res) {
  res.json({ success: true, data: marketService.getAiPicks(), fallback: true });
}

async function quotes(req, res) {
  const symbols = String(req.query.symbols || '')
    .split(',')
    .map((s) => s.trim().toUpperCase())
    .filter(Boolean);

  if (!symbols.length) return res.status(400).json({ success: false, error: 'symbols query param is required' });

  res.json({ success: true, data: marketService.getQuotes(symbols), fallback: true });
}

module.exports = { overview, insight, aiPicks, quotes };

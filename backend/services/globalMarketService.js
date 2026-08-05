const indianMarketService = require('./indianMarketService');

// Global (US) equities for the Global Markets section.
//
// Previously backed by Finnhub. Replaced with the same free Yahoo Finance
// endpoint already used for Sensex/Nifty — verified to return identical
// prices, so dropping the Finnhub key costs nothing. One less key to manage,
// one less free-tier quota to worry about.
const SYMBOLS = [
  { symbol: 'AAPL', display: 'AAPL', name: 'Apple' },
  { symbol: 'MSFT', display: 'MSFT', name: 'Microsoft' },
  { symbol: 'GOOGL', display: 'GOOGL', name: 'Alphabet' },
  { symbol: 'AMZN', display: 'AMZN', name: 'Amazon' },
  { symbol: 'NVDA', display: 'NVDA', name: 'NVIDIA' },
];

/// Returns [] on failure so the Home screen hides the section rather than
/// rendering an empty or fake one.
async function getGlobalStocks() {
  const items = await indianMarketService.fetchQuotes('globalStocks', SYMBOLS);
  return items || [];
}

module.exports = { getGlobalStocks, SYMBOLS };

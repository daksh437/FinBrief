const { db } = require('../config/firebaseAdmin');

function portfolioRef(uid) {
  return db.collection('users').doc(uid).collection('portfolio');
}

async function list(req, res) {
  const snap = await portfolioRef(req.user.uid).get();
  const items = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  res.json({ success: true, data: items });
}

async function add(req, res) {
  const { symbol, name, quantity, avgPrice } = req.body;
  if (!symbol || quantity == null || avgPrice == null) {
    return res.status(400).json({ success: false, error: 'symbol, quantity, and avgPrice are required' });
  }

  await portfolioRef(req.user.uid)
    .doc(symbol.toUpperCase())
    .set({
      symbol: symbol.toUpperCase(),
      name: name || null,
      quantity: Number(quantity),
      avgPrice: Number(avgPrice),
      addedAt: Date.now(),
    });

  res.json({ success: true, data: { symbol: symbol.toUpperCase() } });
}

async function update(req, res) {
  const { symbol } = req.params;
  const { quantity, avgPrice } = req.body;

  const patch = {};
  if (quantity != null) patch.quantity = Number(quantity);
  if (avgPrice != null) patch.avgPrice = Number(avgPrice);

  await portfolioRef(req.user.uid).doc(symbol.toUpperCase()).set(patch, { merge: true });
  res.json({ success: true, data: { symbol: symbol.toUpperCase() } });
}

// Deterministic, logic-based insight from the user's own holdings — free,
// no Gemini call, no aiAccess credit cost (unlike the real /ai/* routes).
async function insight(req, res) {
  const snap = await portfolioRef(req.user.uid).get();
  const items = snap.docs.map((d) => d.data());

  if (items.length === 0) {
    return res.json({ success: true, data: { insight: 'Add holdings to see personalized portfolio insights.' } });
  }

  const values = items.map((i) => ({ symbol: i.symbol, value: i.quantity * i.avgPrice }));
  const total = values.reduce((sum, v) => sum + v.value, 0);
  const top = values.reduce((a, b) => (b.value > a.value ? b : a));
  const topPercent = total > 0 ? (top.value / total) * 100 : 0;

  let text;
  if (items.length === 1) {
    text = `Your portfolio is 100% in ${top.symbol}. Consider diversifying across a few more holdings to spread risk.`;
  } else if (topPercent > 50) {
    text = `${top.symbol} makes up ${topPercent.toFixed(0)}% of your portfolio — a fairly concentrated position. Consider diversifying further.`;
  } else {
    text = `Your portfolio is spread across ${items.length} holdings, with ${top.symbol} as your largest position at ${topPercent.toFixed(0)}%.`;
  }

  res.json({ success: true, data: { insight: text } });
}

async function remove(req, res) {
  const { symbol } = req.params;
  await portfolioRef(req.user.uid).doc(symbol.toUpperCase()).delete();
  res.json({ success: true, data: { symbol: symbol.toUpperCase() } });
}

module.exports = { list, add, update, remove, insight };

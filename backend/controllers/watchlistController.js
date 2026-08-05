const { db } = require('../config/firebaseAdmin');

function watchlistRef(uid) {
  return db.collection('users').doc(uid).collection('watchlist');
}

async function list(req, res) {
  const snap = await watchlistRef(req.user.uid).get();
  const items = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  res.json({ success: true, data: items });
}

async function add(req, res) {
  const { symbol, name, alertPrice, type } = req.body;
  if (!symbol) return res.status(400).json({ success: false, error: 'symbol is required' });

  await watchlistRef(req.user.uid).doc(symbol.toUpperCase()).set({
    symbol: symbol.toUpperCase(),
    name: name || null,
    alertPrice: alertPrice || null,
    type: type || 'Stocks',
    addedAt: Date.now(),
  });

  res.json({ success: true, data: { symbol: symbol.toUpperCase() } });
}

async function update(req, res) {
  const { symbol } = req.params;
  const { alertPrice } = req.body;

  await watchlistRef(req.user.uid).doc(symbol.toUpperCase()).set({ alertPrice: alertPrice ?? null }, { merge: true });
  res.json({ success: true, data: { symbol: symbol.toUpperCase() } });
}

async function remove(req, res) {
  const { symbol } = req.params;
  await watchlistRef(req.user.uid).doc(symbol.toUpperCase()).delete();
  res.json({ success: true, data: { symbol: symbol.toUpperCase() } });
}

module.exports = { list, add, update, remove };

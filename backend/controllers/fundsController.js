const amfi = require('../services/amfiService');
const { db } = require('../config/firebaseAdmin');

/// Scheme search for the "add a fund" flow.
async function search(req, res) {
  const { q } = req.query;
  const results = await amfi.search(q, { limit: 20 });
  res.json({ success: true, data: results });
}

/// The user's funds, each with today's NAV and their gain.
///
/// NAV is attached here rather than stored on the holding, for the same reason
/// stock prices are: a saved NAV is a stale NAV the moment it is written, and
/// on a money screen a stale figure presented as current is worse than none.
async function list(req, res) {
  const snap = await db.collection('users').doc(req.user.uid).collection('funds').get();
  const holdings = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  if (!holdings.length) return res.json({ success: true, data: [] });

  const navs = await amfi.navFor(holdings.map((h) => h.schemeCode));
  const byCode = Object.fromEntries(navs.map((n) => [n.code, n]));

  const data = holdings.map((h) => {
    const scheme = byCode[h.schemeCode];
    // units × NAV. Users hold units, not a rupee amount — a SIP buys a
    // different number each month, so the invested figure and the current
    // value only line up through units.
    const currentValue = scheme && h.units ? scheme.nav * h.units : null;

    return {
      ...h,
      nav: scheme ? scheme.nav : null,
      navDate: scheme ? scheme.date : null,
      name: scheme ? scheme.name : h.name,
      currentValue,
      gain: currentValue != null && h.invested ? currentValue - h.invested : null,
    };
  });

  res.json({ success: true, data });
}

async function add(req, res) {
  const { schemeCode, name, units, invested } = req.body;
  if (!schemeCode) {
    return res.status(400).json({ success: false, error: 'schemeCode is required' });
  }

  // Confirm the scheme exists before storing it, so a bad code can't sit in a
  // user's list forever showing no NAV.
  const [scheme] = await amfi.navFor([schemeCode]);
  if (!scheme) return res.status(400).json({ success: false, error: 'UNKNOWN_SCHEME' });

  const ref = db.collection('users').doc(req.user.uid).collection('funds').doc(String(schemeCode));
  await ref.set(
    {
      schemeCode: String(schemeCode),
      name: name || scheme.name,
      units: Number(units) || null,
      invested: Number(invested) || null,
      addedAt: Date.now(),
    },
    { merge: true }
  );

  res.json({ success: true, data: { schemeCode: String(schemeCode) } });
}

async function remove(req, res) {
  await db
    .collection('users')
    .doc(req.user.uid)
    .collection('funds')
    .doc(String(req.params.schemeCode))
    .delete();
  res.json({ success: true });
}

module.exports = { search, list, add, remove };

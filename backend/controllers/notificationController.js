const { db } = require('../config/firebaseAdmin');

// Populated by future cron jobs (breaking news, morning brief, evening
// summary, portfolio/premium alerts) — currently just reads whatever's in
// Firestore, which is an empty inbox until those jobs exist.
async function listInbox(req, res) {
  const snap = await db
    .collection('users')
    .doc(req.user.uid)
    .collection('notifications')
    .orderBy('createdAt', 'desc')
    .limit(50)
    .get();

  const items = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  res.json({ success: true, data: items });
}

async function registerToken(req, res) {
  const { fcmToken } = req.body;
  if (!fcmToken) return res.status(400).json({ success: false, error: 'fcmToken is required' });

  await db.collection('users').doc(req.user.uid).set({ fcmToken }, { merge: true });
  res.json({ success: true, data: { registered: true } });
}

const DEFAULT_PREFS = {
  pushAlerts: true,
  morningBrief: true,
  eveningSummary: true,
  premiumAlerts: false,
  whatsapp: false,
};

async function getPreferences(req, res) {
  const doc = await db.collection('users').doc(req.user.uid).get();
  const prefs = { ...DEFAULT_PREFS, ...((doc.exists && doc.data().notificationPrefs) || {}) };
  res.json({ success: true, data: prefs });
}

async function updatePreferences(req, res) {
  const { pushAlerts, morningBrief, eveningSummary, premiumAlerts, whatsapp } = req.body;
  const isPremium = req.user.plan === 'premium';

  if ((premiumAlerts || whatsapp) && !isPremium) {
    return res.status(200).json({ success: false, error: 'PREMIUM_ALERTS_REQUIRE_PREMIUM' });
  }

  const prefs = {
    pushAlerts: pushAlerts ?? true,
    morningBrief: morningBrief ?? true,
    eveningSummary: eveningSummary ?? true,
    premiumAlerts: premiumAlerts ?? false,
    whatsapp: whatsapp ?? false,
  };
  await db.collection('users').doc(req.user.uid).set({ notificationPrefs: prefs }, { merge: true });
  res.json({ success: true, data: prefs });
}

module.exports = { listInbox, registerToken, getPreferences, updatePreferences };

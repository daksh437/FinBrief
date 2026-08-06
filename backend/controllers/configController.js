const { db } = require('../config/firebaseAdmin');
const { DAILY_LIMIT_FREE, DAILY_LIMIT_PREMIUM } = require('../middleware/aiAccess');

// Server-driven client config (v11 `app_config`). Values live in a single
// app_config/client document so they can be changed without shipping an app
// update; every field has a safe default if the doc doesn't exist yet.
const DEFAULTS = {
  minSupportedVersion: '1.0.0',
  forceUpdate: false,
  dailyLimitFree: DAILY_LIMIT_FREE,
  dailyLimitPremium: DAILY_LIMIT_PREMIUM,
  features: {
    aiChat: true,
    voiceSummary: true,
    portfolio: true,
    whatsappAlerts: true,
  },
};

async function get(req, res) {
  let stored = {};
  try {
    const doc = await db.collection('app_config').doc('client').get();
    if (doc.exists) stored = doc.data();
  } catch (err) {
    // Config is non-critical — fall back to defaults rather than failing the
    // request and blocking app startup.
    console.error('[app_config] read failed:', err.message);
  }

  res.json({
    success: true,
    data: {
      ...DEFAULTS,
      ...stored,
      features: { ...DEFAULTS.features, ...(stored.features || {}) },
    },
  });
}

module.exports = { get, DEFAULTS };

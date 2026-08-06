const { db } = require('../config/firebaseAdmin');

// Two tiers, no trial and no purchasable credits.
//
// The free trial was dropped in favour of a ₹49 first month: a free trial
// spends Gemini quota on people who were never going to pay, while someone who
// has already paid ₹49 has a card on file and renews by default.
//
// PREMIUM IS NOT LITERALLY UNLIMITED. At ₹999/year the net is about ₹85 a
// month, and 100 AI calls a day would cost more than that in Gemini usage. A
// real user does 10-15, so the cap is invisible to them but stops one runaway
// account (or a script) from turning a subscriber into a loss. The Terms say
// "unlimited, subject to fair use" for this reason.
const DAILY_LIMIT_FREE = Number(process.env.DAILY_LIMIT_FREE || 5);
const DAILY_LIMIT_PREMIUM = Number(process.env.DAILY_LIMIT_PREMIUM || 100);
const IDEMPOTENCY_TTL_MS = 48 * 60 * 60 * 1000;

function todayUtcKey() {
  return new Date().toISOString().slice(0, 10); // YYYY-MM-DD, resets at midnight UTC
}

const limitFor = (user) => (user.plan === 'premium' ? DAILY_LIMIT_PREMIUM : DAILY_LIMIT_FREE);

// Gate for every /ai/* route. Enforces the daily limit server-side from
// Firestore. Client-side counters are advisory only — never trust them for the
// actual check.
async function aiAccess(req, res, next) {
  if (process.env.DEV_SKIP_LIMITS === 'true' && process.env.NODE_ENV !== 'production') {
    return next();
  }

  const uid = req.user && req.user.uid;
  if (!uid) {
    return res.status(401).json({ success: false, error: 'Not authenticated' });
  }

  const userRef = db.collection('users').doc(uid);

  try {
    const idempotencyKey = req.headers['x-idempotency-key'];
    if (idempotencyKey) {
      const keyRef = db.collection('ai_request_keys').doc(idempotencyKey);
      const keyDoc = await keyRef.get();
      if (keyDoc.exists) {
        return res.json({ success: true, data: keyDoc.data().response, idempotent: true });
      }
      req._idempotencyKeyRef = keyRef;
    }

    const userSnap = await userRef.get();
    const user = userSnap.exists ? userSnap.data() : {};

    const limit = limitFor(user);
    const day = todayUtcKey();

    // Counting inside a transaction so two devices can't both slip through on
    // the last remaining call of the day.
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(userRef);
      const usage = (snap.exists && snap.data().aiUsage) || {};
      const usedToday = usage.date === day ? usage.count || 0 : 0;

      if (usedToday >= limit) {
        throw Object.assign(new Error('DAILY_LIMIT_REACHED'), {
          code: 'DAILY_LIMIT_REACHED',
          // Carried on the error so the response can tell a free user (who
          // should see an upgrade prompt) from a premium user who has hit the
          // fair-use ceiling and must not be asked to buy anything.
          plan: user.plan === 'premium' ? 'premium' : 'free',
          limit,
        });
      }

      tx.set(userRef, { aiUsage: { date: day, count: usedToday + 1 } }, { merge: true });
    });

    next();
  } catch (err) {
    if (err.code === 'DAILY_LIMIT_REACHED') {
      return res.status(200).json({
        success: false,
        // Kept as INSUFFICIENT_CREDITS so older installs still show their
        // upgrade prompt instead of a generic failure.
        error: 'INSUFFICIENT_CREDITS',
        plan: err.plan,
        dailyLimit: err.limit,
      });
    }
    console.error('aiAccess middleware error:', err);
    res.status(500).json({ success: false, error: 'Access check failed' });
  }
}

// Wraps a route handler's successful response so it gets cached against the
// idempotency key, if one was provided on the request.
function withIdempotency(handler) {
  return async (req, res, next) => {
    const originalJson = res.json.bind(res);
    res.json = (body) => {
      if (req._idempotencyKeyRef && body && body.success) {
        req._idempotencyKeyRef
          .set({ response: body.data, createdAt: Date.now(), expiresAt: Date.now() + IDEMPOTENCY_TTL_MS })
          .catch((err) => console.error('idempotency write failed:', err));
      }
      return originalJson(body);
    };
    return handler(req, res, next);
  };
}

module.exports = { aiAccess, withIdempotency, DAILY_LIMIT_FREE, DAILY_LIMIT_PREMIUM };

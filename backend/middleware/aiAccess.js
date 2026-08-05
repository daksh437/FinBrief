const { db } = require('../config/firebaseAdmin');

const TRIAL_DAYS = 7;
const DAILY_CREDITS_FREE = Number(process.env.DAILY_CREDITS_FREE || 3);
const IDEMPOTENCY_TTL_MS = 48 * 60 * 60 * 1000;

function todayUtcKey() {
  return new Date().toISOString().slice(0, 10); // YYYY-MM-DD, resets at midnight UTC
}

function isInTrial(user) {
  if (!user.trialStartedAt) return false;
  const started = user.trialStartedAt.toDate ? user.trialStartedAt.toDate() : new Date(user.trialStartedAt);
  const ageMs = Date.now() - started.getTime();
  return ageMs < TRIAL_DAYS * 24 * 60 * 60 * 1000;
}

// Gate for every /ai/* route. Enforces trial / free-daily-credit / premium-unlimited
// access server-side from Firestore. Client-side counters are advisory only —
// never trust them for the actual limit check.
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

    if (user.plan === 'premium') {
      return next();
    }

    if (isInTrial(user)) {
      return next();
    }

    const day = todayUtcKey();

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(userRef);
      const usage = (snap.exists && snap.data().aiUsage) || {};
      const usedToday = usage.date === day ? usage.count || 0 : 0;

      if (usedToday >= DAILY_CREDITS_FREE) {
        throw Object.assign(new Error('INSUFFICIENT_CREDITS'), { code: 'INSUFFICIENT_CREDITS' });
      }

      tx.set(userRef, { aiUsage: { date: day, count: usedToday + 1 } }, { merge: true });
    });

    next();
  } catch (err) {
    if (err.code === 'INSUFFICIENT_CREDITS') {
      return res.status(200).json({
        success: false,
        error: 'INSUFFICIENT_CREDITS',
        dailyLimit: DAILY_CREDITS_FREE,
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

module.exports = { aiAccess, withIdempotency, DAILY_CREDITS_FREE, TRIAL_DAYS };

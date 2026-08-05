// Lightweight in-memory rate limiter (v11 Security).
//
// Deliberately in-process rather than Redis-backed: this backend runs as a
// single Render instance today. If it's ever scaled to multiple instances,
// each would keep its own counters and the effective limit would multiply —
// swap in a shared store at that point.
const buckets = new Map();

// Keyed by authenticated uid when available so one user on a shared/NAT'd IP
// can't exhaust everyone else's quota.
function keyFor(req) {
  return req.user?.uid || req.ip || 'unknown';
}

function rateLimit({ windowMs = 60_000, max = 60, name = 'default' } = {}) {
  return (req, res, next) => {
    const key = `${name}:${keyFor(req)}`;
    const now = Date.now();
    const entry = buckets.get(key);

    if (!entry || now > entry.resetAt) {
      buckets.set(key, { count: 1, resetAt: now + windowMs });
      return next();
    }

    entry.count += 1;
    if (entry.count > max) {
      const retryAfter = Math.ceil((entry.resetAt - now) / 1000);
      res.set('Retry-After', String(retryAfter));
      return res.status(429).json({
        success: false,
        error: 'RATE_LIMITED',
        message: `Too many requests. Try again in ${retryAfter}s.`,
      });
    }

    next();
  };
}

// Periodically drop expired buckets so the map can't grow without bound.
// unref() keeps this timer from holding the process open.
const cleanup = setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of buckets) {
    if (now > entry.resetAt) buckets.delete(key);
  }
}, 5 * 60_000);
if (typeof cleanup.unref === 'function') cleanup.unref();

module.exports = { rateLimit };

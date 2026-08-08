const { db } = require('../config/firebaseAdmin');
const { DAILY_LIMIT_FREE, DAILY_LIMIT_PREMIUM } = require('../middleware/aiAccess');

const todayKey = () => new Date().toISOString().slice(0, 10);
const since = (hours) => Date.now() - hours * 60 * 60 * 1000;

/// Headline numbers for the dashboard.
///
/// Every figure here was something previously answered by running an ad-hoc
/// script against Firestore — including the AI call count that turned out to
/// be the reason the Gemini bill was what it was.
async function overview(req, res) {
  const today = todayKey();

  const [users, news, archive] = await Promise.all([
    db.collection('users').get(),
    db.collection('news').count().get().catch(() => null),
    db.collection('news_archive').count().get().catch(() => null),
  ]);

  let premium = 0;
  let activeToday = 0;
  let aiUsedToday = 0;
  let withPushToken = 0;

  users.docs.forEach((d) => {
    const u = d.data();
    if (u.plan === 'premium') premium += 1;
    if (u.fcmToken) withPushToken += 1;
    if (u.aiUsage && u.aiUsage.date === today) {
      activeToday += 1;
      aiUsedToday += u.aiUsage.count || 0;
    }
  });

  // AI call volume from the monitoring log — the number that actually drives
  // the bill, as opposed to per-user usage which excludes cron work.
  let aiCalls24h = 0;
  let aiFailures24h = 0;
  let cacheHits24h = 0;
  try {
    const snap = await db.collection('admin_logs').where('createdAt', '>', since(24)).get();
    snap.docs.forEach((d) => {
      const event = d.data().event;
      if (event === 'ai_call') aiCalls24h += 1;
      else if (event === 'ai_failure') aiFailures24h += 1;
      else if (event === 'ai_cache_hit') cacheHits24h += 1;
    });
  } catch {
    // Logs are best-effort; the rest of the dashboard still renders.
  }

  res.json({
    success: true,
    data: {
      users: users.size,
      premium,
      free: users.size - premium,
      activeToday,
      withPushToken,
      aiUsedToday,
      aiCalls24h,
      aiFailures24h,
      cacheHits24h,
      newsStored: news ? news.data().count : null,
      archived: archive ? archive.data().count : null,
      limits: { free: DAILY_LIMIT_FREE, premium: DAILY_LIMIT_PREMIUM },
    },
  });
}

async function listUsers(req, res) {
  const today = todayKey();
  const snap = await db.collection('users').limit(200).get();

  const data = snap.docs.map((d) => {
    const u = d.data();
    const usage = u.aiUsage || {};
    return {
      uid: d.id,
      email: u.email || null,
      plan: u.plan || 'free',
      isAdmin: u.isAdmin === true,
      hasPushToken: Boolean(u.fcmToken),
      usedToday: usage.date === today ? usage.count || 0 : 0,
      createdAt: u.createdAt || null,
    };
  });

  data.sort((a, b) => (b.createdAt || 0) - (a.createdAt || 0));
  res.json({ success: true, data });
}

/// Grants or removes Premium — for testers, and for putting right a purchase
/// that failed to apply.
///
/// Deliberately cannot grant admin: that stays a service-account-only write,
/// so a compromised admin account can't mint more admins.
async function setPlan(req, res) {
  const { uid } = req.params;
  const { plan } = req.body;

  if (!['free', 'premium'].includes(plan)) {
    return res.status(400).json({ success: false, error: "plan must be 'free' or 'premium'" });
  }

  const ref = db.collection('users').doc(uid);
  if (!(await ref.get()).exists) {
    return res.status(404).json({ success: false, error: 'No such user' });
  }

  await ref.set(
    {
      plan,
      premiumSince: plan === 'premium' ? Date.now() : null,
      // Recorded so a manual grant is distinguishable from a real purchase
      // when reconciling revenue.
      planGrantedBy: req.user.uid,
      planGrantedAt: Date.now(),
    },
    { merge: true }
  );

  res.json({ success: true, data: { uid, plan } });
}

/// Recent errors, newest first — the ones worth waking up for.
async function errors(req, res) {
  try {
    const snap = await db
      .collection('admin_logs')
      .where('createdAt', '>', since(48))
      .limit(500)
      .get();

    const data = snap.docs
      .map((d) => ({ id: d.id, ...d.data() }))
      .filter((l) => l.level === 'error')
      .sort((a, b) => (b.createdAt || 0) - (a.createdAt || 0))
      .slice(0, 50);

    res.json({ success: true, data });
  } catch (err) {
    res.json({ success: true, data: [], note: err.message });
  }
}

async function feedback(req, res) {
  const snap = await db.collection('feedback').orderBy('createdAt', 'desc').limit(50).get();
  res.json({ success: true, data: snap.docs.map((d) => ({ id: d.id, ...d.data() })) });
}

module.exports = { overview, listUsers, setPlan, errors, feedback };

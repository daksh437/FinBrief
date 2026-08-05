const cron = require('node-cron');
const newsPipeline = require('../services/newsPipeline');
const pushEngine = require('../services/pushEngine');
const monitoring = require('../services/monitoringService');
const newsArchive = require('../services/newsArchiveService');
const { db } = require('../config/firebaseAdmin');

// Scheduled workers (v12 §6). All disabled unless ENABLE_CRON_JOBS=true so
// local dev and tests never fire real pushes or burn API quota.
//
// COST NOTE — v12 specifies "breaking news every 30 sec" (~2,880 runs/day).
// News fetching itself is now free and unmetered (RSS), so polling frequency
// is no longer quota-limited. The remaining cost is AI enrichment: roughly 3
// Gemini calls per article, bounded by AI_ENRICH_LIMIT per run.
//
// Default is every 5 minutes, which is ample for FinBrief's audience (retail
// investors reading for understanding, not sub-minute traders). Shorten via
// CRON_BREAKING if desired, keeping an eye on Gemini spend.
const SCHEDULES = {
  breaking: process.env.CRON_BREAKING || '*/5 * * * *',
  refresh: process.env.CRON_REFRESH || '*/30 * * * *',
  cleanup: process.env.CRON_CLEANUP || '0 3 * * *',
  analytics: process.env.CRON_ANALYTICS || '0 * * * *',
  morningBrief: process.env.CRON_MORNING || '30 3 * * *', // 09:00 IST (UTC+5:30)
  eveningBrief: process.env.CRON_EVENING || '30 12 * * *', // 18:00 IST
};

/// Fetch + enrich, then route each article by priority.
async function runBreakingJob() {
  const { stored = [] } = await newsPipeline.run({ limit: 20 });
  for (const article of stored) {
    await pushEngine.dispatch(article);
  }
  return { processed: stored.length };
}

/// Wider refresh across categories to keep the feed warm.
async function runRefreshJob() {
  for (const category of ['business', 'technology', 'general']) {
    await newsPipeline.run({ category, limit: 20 });
  }
}

/// Drops stale pipeline data so Firestore doesn't grow without bound.
async function runCleanupJob() {
  const cutoff = Date.now() - 7 * 24 * 60 * 60 * 1000;
  let deleted = 0;

  for (const name of ['news_cache', 'ai_history', 'admin_logs']) {
    try {
      const field = name === 'news_cache' ? 'cachedAt' : name === 'ai_history' ? 'timestamp' : 'createdAt';
      const snap = await db.collection(name).where(field, '<', cutoff).limit(400).get();
      if (snap.empty) continue;

      const batch = db.batch();
      snap.docs.forEach((d) => batch.delete(d.ref));
      await batch.commit();
      deleted += snap.size;
    } catch (err) {
      monitoring.logApiFailure(`cleanup:${name}`, err.message);
    }
  }

  // The archive has its own retention window and query shape.
  deleted += await newsArchive.prune();

  monitoring.write('info', 'cleanup_run', { deleted });
  return { deleted };
}

/// Hourly counts for basic operational visibility.
async function runAnalyticsJob() {
  try {
    const [users, news] = await Promise.all([
      db.collection('users').count().get(),
      db.collection('news').count().get(),
    ]);
    const stats = { users: users.data().count, news: news.data().count };
    monitoring.write('info', 'analytics_snapshot', stats);
    return stats;
  } catch (err) {
    monitoring.logApiFailure('analytics', err.message);
    return null;
  }
}

function schedule(name, expression, fn) {
  if (!cron.validate(expression)) {
    console.error(`[jobs] invalid cron for ${name}: "${expression}" — job not scheduled`);
    return;
  }
  cron.schedule(expression, async () => {
    try {
      await fn();
    } catch (err) {
      monitoring.logApiFailure(`job:${name}`, err.message);
    }
  });
  console.log(`[jobs] ${name}: ${expression}`);
}

function startJobs() {
  if (process.env.ENABLE_CRON_JOBS !== 'true') {
    console.log('[jobs] cron disabled (set ENABLE_CRON_JOBS=true to enable)');
    return;
  }

  schedule('breaking', SCHEDULES.breaking, runBreakingJob);
  schedule('refresh', SCHEDULES.refresh, runRefreshJob);
  schedule('cleanup', SCHEDULES.cleanup, runCleanupJob);
  schedule('analytics', SCHEDULES.analytics, runAnalyticsJob);
  schedule('morningBrief', SCHEDULES.morningBrief, () => pushEngine.sendBrief('morning'));
  schedule('eveningBrief', SCHEDULES.eveningBrief, () => pushEngine.sendBrief('evening'));
}

module.exports = {
  startJobs,
  runBreakingJob,
  runRefreshJob,
  runCleanupJob,
  runAnalyticsJob,
  SCHEDULES,
};

const { db } = require('../config/firebaseAdmin');
const notificationService = require('./notificationService');
const monitoring = require('./monitoringService');

// v12 §7: high-priority breaking news goes out instantly; everything else is
// queued and batched into the morning / evening briefs so users aren't spammed.

/// Users who haven't disabled the given notification type.
/// `prefKey` maps to the toggles built in the v5 Alert Settings screen.
async function eligibleUsers(prefKey) {
  const snap = await db.collection('users').get();
  return snap.docs
    .map((d) => ({ uid: d.id, ...d.data() }))
    .filter((u) => (u.notificationPrefs?.[prefKey] ?? true) !== false);
}

async function writeInbox(uid, entry) {
  try {
    await db.collection('users').doc(uid).collection('notifications').add({
      read: false,
      createdAt: Date.now(),
      ...entry,
    });
    return true;
  } catch (err) {
    monitoring.logApiFailure('firestore:notifications', `${uid}: ${err.message}`);
    return false;
  }
}

/// Sends immediately to every eligible user (inbox + FCM).
async function sendInstant(article) {
  const users = await eligibleUsers('pushAlerts');
  const tokens = [];
  let inboxWrites = 0;

  await Promise.all(
    users.map(async (user) => {
      if (user.fcmToken) tokens.push(user.fcmToken);
      const ok = await writeInbox(user.uid, {
        title: article.headline,
        body: article.aiSummary || '',
        type: 'breaking_news',
        articleId: article.headlineHash,
        articleUrl: article.url || null,
        priority: 'high',
      });
      if (ok) inboxWrites += 1;
    })
  );

  let pushed = 0;
  if (tokens.length) {
    try {
      const res = await notificationService.sendToTokens(tokens, {
        title: article.headline,
        body: article.aiSummary || '',
        data: { type: 'breaking_news', articleId: String(article.headlineHash) },
      });
      pushed = res?.successCount ?? tokens.length;
    } catch (err) {
      // Push failure must not undo the inbox writes above.
      monitoring.logApiFailure('fcm', err.message);
    }
  }

  monitoring.logNotificationDelivery({ kind: 'instant', users: users.length, inboxWrites, pushed });
  return { users: users.length, inboxWrites, pushed };
}

/// Queues a low/medium-priority article for the next brief.
async function queueForBrief(article) {
  try {
    await db.collection('news_digest_queue').doc(article.headlineHash).set({
      headline: article.headline,
      aiSummary: article.aiSummary || null,
      category: article.category || null,
      priority: article.priority,
      queuedAt: Date.now(),
    });
  } catch (err) {
    monitoring.logApiFailure('firestore:digest_queue', err.message);
  }
}

/// Routes a processed article by priority (called by the pipeline job).
async function dispatch(article) {
  if (article.priority === 'high') return sendInstant(article);
  await queueForBrief(article);
  return { queued: true };
}

/// Builds and sends the morning/evening brief from the queue, then clears it.
/// [slot] is 'morning' or 'evening'.
async function sendBrief(slot) {
  const prefKey = slot === 'morning' ? 'morningBrief' : 'eveningSummary';
  const type = slot === 'morning' ? 'morning_brief' : 'evening_summary';

  let queued = [];
  try {
    const snap = await db.collection('news_digest_queue').orderBy('queuedAt', 'desc').limit(10).get();
    queued = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  } catch (err) {
    monitoring.logApiFailure('firestore:digest_queue', err.message);
    return { sent: 0, reason: 'queue read failed' };
  }

  if (!queued.length) return { sent: 0, reason: 'queue empty' };

  const title = slot === 'morning' ? 'Your Morning Brief' : 'Your Evening Summary';
  const body = queued
    .slice(0, 3)
    .map((q) => q.headline)
    .join(' • ');

  const users = await eligibleUsers(prefKey);
  const tokens = [];
  let inboxWrites = 0;

  await Promise.all(
    users.map(async (user) => {
      if (user.fcmToken) tokens.push(user.fcmToken);
      const ok = await writeInbox(user.uid, {
        title,
        body,
        type,
        priority: 'low',
        headlines: queued.slice(0, 5).map((q) => q.headline),
      });
      if (ok) inboxWrites += 1;
    })
  );

  let pushed = 0;
  if (tokens.length) {
    try {
      const res = await notificationService.sendToTokens(tokens, { title, body, data: { type } });
      pushed = res?.successCount ?? tokens.length;
    } catch (err) {
      monitoring.logApiFailure('fcm', err.message);
    }
  }

  // Clear the queue only after delivery so a failure keeps items for retry.
  try {
    const batch = db.batch();
    queued.forEach((q) => batch.delete(db.collection('news_digest_queue').doc(q.id)));
    await batch.commit();
  } catch (err) {
    monitoring.logApiFailure('firestore:digest_queue_clear', err.message);
  }

  monitoring.logNotificationDelivery({ kind: type, users: users.length, inboxWrites, pushed, items: queued.length });
  return { sent: users.length, inboxWrites, pushed, items: queued.length };
}

module.exports = { dispatch, sendInstant, sendBrief, queueForBrief, eligibleUsers };

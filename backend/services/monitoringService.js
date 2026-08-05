const { db } = require('../config/firebaseAdmin');

// Pipeline observability (v12 §9): API failures, AI failures, processing time
// and notification delivery. Writes to `admin_logs`.
//
// Every function is fire-and-forget and swallows its own errors — monitoring
// must never be the thing that breaks the pipeline it's watching.
function write(level, event, details = {}) {
  const entry = { level, event, ...details, createdAt: Date.now() };

  // Always surface to stdout too, so Render logs show it even if Firestore
  // is the thing that's broken.
  const line = `[monitor:${level}] ${event} ${JSON.stringify(details)}`;
  if (level === 'error') console.error(line);
  else console.log(line);

  db.collection('admin_logs')
    .add(entry)
    .catch((err) => console.error('[monitor] admin_logs write failed:', err.message));
}

const logApiFailure = (source, message) => write('error', 'api_failure', { source, message });
const logAiFailure = (action, message) => write('error', 'ai_failure', { action, message });
const logPipelineRun = (stats) => write('info', 'pipeline_run', stats);
const logNotificationDelivery = (stats) => write('info', 'notification_delivery', stats);

/// Times an async operation and logs how long it took, tagging failures too.
async function timed(label, fn) {
  const start = Date.now();
  try {
    const result = await fn();
    write('info', 'timing', { label, ms: Date.now() - start, ok: true });
    return result;
  } catch (err) {
    write('error', 'timing', { label, ms: Date.now() - start, ok: false, message: err.message });
    throw err;
  }
}

module.exports = {
  write,
  logApiFailure,
  logAiFailure,
  logPipelineRun,
  logNotificationDelivery,
  timed,
};

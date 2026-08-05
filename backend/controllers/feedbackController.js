const { db } = require('../config/firebaseAdmin');

// Stores user-submitted feedback / bug reports in a top-level `feedback`
// collection (per the v8 blueprint's Firestore collection list). Kept
// top-level rather than under the user doc so it can be reviewed in one place.
async function submit(req, res) {
  const message = String(req.body?.message || '').trim();
  const type = String(req.body?.type || 'feedback');

  if (!message) {
    return res.status(400).json({ success: false, error: 'message is required' });
  }

  const doc = await db.collection('feedback').add({
    uid: req.user.uid,
    email: req.user.email || null,
    type,
    message: message.slice(0, 5000),
    createdAt: Date.now(),
  });

  res.json({ success: true, data: { id: doc.id } });
}

module.exports = { submit };

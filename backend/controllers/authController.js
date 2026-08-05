const { db } = require('../config/firebaseAdmin');

// Called once right after Firebase sign-in/sign-up. Creates the Firestore
// user profile (and starts the trial) if this is the first time we've seen
// this uid; otherwise just returns the existing profile.
async function bootstrap(req, res) {
  const userRef = db.collection('users').doc(req.user.uid);
  const doc = await userRef.get();

  if (!doc.exists) {
    const profile = {
      uid: req.user.uid,
      email: req.user.email || null,
      plan: 'free',
      trialStartedAt: Date.now(),
      creditBalance: 0,
      createdAt: Date.now(),
    };
    await userRef.set(profile);
    return res.json({ success: true, data: profile, isNewUser: true });
  }

  res.json({ success: true, data: doc.data(), isNewUser: false });
}

async function profile(req, res) {
  const doc = await db.collection('users').doc(req.user.uid).get();
  if (!doc.exists) return res.status(404).json({ success: false, error: 'Profile not found — call /auth/bootstrap first' });
  res.json({ success: true, data: doc.data() });
}

module.exports = { bootstrap, profile };

const { db, auth } = require('../config/firebaseAdmin');

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

// Sub-collections hanging off users/{uid} that must go with the account.
const USER_SUBCOLLECTIONS = ['bookmarks', 'watchlist', 'portfolio', 'notifications', 'purchases'];

/// Deletes a collection in pages — a heavy user's bookmarks can exceed the
/// 500-write batch limit.
async function purgeCollection(ref) {
  for (;;) {
    const snap = await ref.limit(400).get();
    if (snap.empty) return;

    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();

    if (snap.size < 400) return;
  }
}

/// Permanently deletes the signed-in user's account and their data.
///
/// Google Play requires apps that let users create an account to offer
/// deletion from inside the app, so this is a store requirement, not a
/// nice-to-have.
///
/// Order matters: application data goes first, then the Auth user. The other
/// way round, a failure at the second step would leave orphaned data behind
/// with no owner and no way for anyone to reach it.
async function deleteAccount(req, res) {
  const { uid } = req.user;
  const userRef = db.collection('users').doc(uid);

  for (const name of USER_SUBCOLLECTIONS) {
    await purgeCollection(userRef.collection(name));
  }
  await userRef.delete();

  // Records keyed by uid that live outside the user document. A failure here
  // must not block deleting the account itself.
  for (const [name, field] of [
    ['ai_history', 'userId'],
    ['feedback', 'uid'],
    ['news_digest_queue', 'uid'],
  ]) {
    try {
      await purgeCollection(db.collection(name).where(field, '==', uid));
    } catch (err) {
      console.error(`[deleteAccount] ${name} purge failed:`, err.message);
    }
  }

  await auth.deleteUser(uid);
  res.json({ success: true });
}

module.exports = { bootstrap, profile, deleteAccount };

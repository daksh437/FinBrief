const { db } = require('../config/firebaseAdmin');

// Admin gate for /admin routes.
//
// The check is here, on the server, reading the flag from Firestore. Hiding a
// screen in the app is not access control — anyone can call the endpoint
// directly with a valid login, and these routes expose every user's email,
// plan and usage, and can hand out Premium.
//
// The flag is deliberately not settable through any API. It is granted by
// writing isAdmin on the user document with the Admin SDK, which means an
// account can only become admin by someone with the service-account key.
//
// Firestore rules already prevent a client writing to the users collection at
// all, so the flag cannot be self-granted from the app either.
async function requireAdmin(req, res, next) {
  const uid = req.user && req.user.uid;
  if (!uid) return res.status(401).json({ success: false, error: 'Not authenticated' });

  try {
    const doc = await db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data().isAdmin !== true) {
      // 404 rather than 403: a non-admin has no reason to learn these routes
      // exist.
      return res.status(404).json({ success: false, error: 'Not found' });
    }
    return next();
  } catch (err) {
    console.error('[requireAdmin] check failed:', err.message);
    // Fail closed.
    return res.status(500).json({ success: false, error: 'Admin check failed' });
  }
}

module.exports = { requireAdmin };

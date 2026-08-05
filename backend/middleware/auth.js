const { auth, db } = require('../config/firebaseAdmin');

// Verifies the Firebase ID token from the Authorization header and attaches
// req.user = { uid, email, ...firestoreProfile }. Never trust client-supplied
// uid headers directly for anything that touches credits/billing.
async function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;

    if (!token) {
      return res.status(401).json({ success: false, error: 'Missing bearer token' });
    }

    const decoded = await auth.verifyIdToken(token);
    const userDoc = await db.collection('users').doc(decoded.uid).get();

    req.user = {
      uid: decoded.uid,
      email: decoded.email || null,
      ...(userDoc.exists ? userDoc.data() : {}),
    };

    next();
  } catch (err) {
    return res.status(401).json({ success: false, error: 'Invalid or expired token' });
  }
}

module.exports = { requireAuth };

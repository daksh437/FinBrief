const admin = require('firebase-admin');

if (!admin.apps.length) {
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;

  if (serviceAccountJson) {
    admin.initializeApp({
      credential: admin.credential.cert(JSON.parse(serviceAccountJson)),
    });
  } else {
    // Falls back to Application Default Credentials (e.g. GOOGLE_APPLICATION_CREDENTIALS
    // env var pointing at a local service-account file during development).
    admin.initializeApp();
  }
}

const db = admin.firestore();
const auth = admin.auth();
const messaging = admin.messaging();

module.exports = { admin, db, auth, messaging };

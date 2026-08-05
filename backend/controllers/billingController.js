const billingService = require('../services/billingService');
const { db, admin } = require('../config/firebaseAdmin');

async function verify(req, res) {
  const { productId, purchaseToken } = req.body;
  if (!productId || !purchaseToken) {
    return res.status(400).json({ success: false, error: 'productId and purchaseToken are required' });
  }

  const isSubscription = billingService.SUBSCRIPTION_PRODUCT_IDS.has(productId);
  const result = await billingService.verifyPurchase({ productId, purchaseToken, isSubscription });

  if (!result.valid) {
    return res.status(200).json({ success: false, error: 'PURCHASE_NOT_VALID' });
  }

  const userRef = db.collection('users').doc(req.user.uid);
  const creditsGranted = billingService.CREDIT_PACKS[productId] || 0;

  if (isSubscription) {
    await userRef.set({ plan: 'premium', premiumSince: Date.now() }, { merge: true });
  } else if (creditsGranted) {
    await userRef.set({ creditBalance: admin.firestore.FieldValue.increment(creditsGranted) }, { merge: true });
  }

  await userRef.collection('purchases').add({
    productId,
    type: isSubscription ? 'subscription' : 'credits',
    creditsGranted: isSubscription ? null : creditsGranted,
    createdAt: Date.now(),
  });

  res.json({ success: true, data: { productId, applied: true }, mock: result.mock || false });
}

async function status(req, res) {
  const doc = await db.collection('users').doc(req.user.uid).get();
  const data = doc.exists ? doc.data() : {};
  res.json({
    success: true,
    data: {
      plan: data.plan || 'free',
      creditBalance: data.creditBalance || 0,
      trialStartedAt: data.trialStartedAt || null,
    },
  });
}

async function history(req, res) {
  const snap = await db
    .collection('users')
    .doc(req.user.uid)
    .collection('purchases')
    .orderBy('createdAt', 'desc')
    .limit(50)
    .get();

  res.json({ success: true, data: snap.docs.map((d) => ({ id: d.id, ...d.data() })) });
}

module.exports = { verify, status, history };

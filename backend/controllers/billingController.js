const billingService = require('../services/billingService');
const { db } = require('../config/firebaseAdmin');
const { DAILY_LIMIT_FREE, DAILY_LIMIT_PREMIUM } = require('../middleware/aiAccess');

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

  // Subscriptions are the only thing sold now, so anything else reaching here
  // is either a stale client or someone probing the endpoint.
  if (!isSubscription) {
    return res.status(400).json({ success: false, error: 'UNKNOWN_PRODUCT' });
  }

  const userRef = db.collection('users').doc(req.user.uid);
  await userRef.set({ plan: 'premium', premiumSince: Date.now() }, { merge: true });

  await userRef.collection('purchases').add({
    productId,
    type: 'subscription',
    // Which base plan was bought, so renewals and churn can be told apart per
    // period later.
    basePlan: req.body.basePlan || null,
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
      premiumSince: data.premiumSince || null,
      dailyLimit: data.plan === 'premium' ? DAILY_LIMIT_PREMIUM : DAILY_LIMIT_FREE,
      usedToday: data.aiUsage && data.aiUsage.date === new Date().toISOString().slice(0, 10)
          ? data.aiUsage.count || 0
          : 0,
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

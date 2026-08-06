const { google } = require('googleapis');

const PACKAGE_NAME = process.env.ANDROID_PACKAGE_NAME;
const SERVICE_ACCOUNT_JSON = process.env.FIREBASE_SERVICE_ACCOUNT; // reuse the same service account
const MOCK_MODE = !PACKAGE_NAME || !SERVICE_ACCOUNT_JSON;

// One subscription, three base plans. Play models it this way (rather than
// three separate products) so a user can switch period without cancelling, and
// so the ₹49 introductory offer can hang off the monthly plan and be limited
// to first-time subscribers automatically.
//
// Consumable credit packs were removed: two ways to pay on the same paywall
// split the decision and lowered conversion, and a pack buyer spends less over
// a year than a subscriber.
const SUBSCRIPTION_ID = 'finbrief_premium';

const BASE_PLANS = {
  monthly: { id: 'monthly', period: 'P1M', priceInr: 199 },
  sixMonth: { id: 'six-month', period: 'P6M', priceInr: 899 },
  yearly: { id: 'yearly', period: 'P1Y', priceInr: 999 },
};

// Any of these arriving from the client is treated as a subscription purchase.
// `premium_monthly` stays recognised so installs from before the change can
// still be validated instead of silently losing their subscription.
const SUBSCRIPTION_PRODUCT_IDS = new Set([SUBSCRIPTION_ID, 'premium_monthly']);

let androidPublisher = null;
function getAndroidPublisher() {
  if (androidPublisher) return androidPublisher;
  const auth = new google.auth.GoogleAuth({
    credentials: JSON.parse(SERVICE_ACCOUNT_JSON),
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  androidPublisher = google.androidpublisher({ version: 'v3', auth });
  return androidPublisher;
}

async function verifyPurchase({ productId, purchaseToken, isSubscription }) {
  if (MOCK_MODE) {
    return { valid: true, mock: true, productId };
  }

  const publisher = getAndroidPublisher();

  if (isSubscription) {
    const res = await publisher.purchases.subscriptions.get({
      packageName: PACKAGE_NAME,
      subscriptionId: productId,
      token: purchaseToken,
    });
    const active = res.data.expiryTimeMillis && Number(res.data.expiryTimeMillis) > Date.now();
    return { valid: !!active, raw: res.data };
  }

  const res = await publisher.purchases.products.get({
    packageName: PACKAGE_NAME,
    productId,
    token: purchaseToken,
  });
  const purchased = res.data.purchaseState === 0;
  return { valid: purchased, raw: res.data };
}

module.exports = { verifyPurchase, SUBSCRIPTION_ID, BASE_PLANS, SUBSCRIPTION_PRODUCT_IDS, MOCK_MODE };

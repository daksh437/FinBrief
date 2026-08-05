const { google } = require('googleapis');

const PACKAGE_NAME = process.env.ANDROID_PACKAGE_NAME;
const SERVICE_ACCOUNT_JSON = process.env.FIREBASE_SERVICE_ACCOUNT; // reuse the same service account
const MOCK_MODE = !PACKAGE_NAME || !SERVICE_ACCOUNT_JSON;

// Placeholder SKU -> credit-count map. Replace with the real Play Console
// product ids and amounts once the credit-pack pricing is finalized.
const CREDIT_PACKS = {
  credits_pack_small: 50,
  credits_pack_large: 150,
};

const SUBSCRIPTION_PRODUCT_IDS = new Set(['premium_monthly']);

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

module.exports = { verifyPurchase, CREDIT_PACKS, SUBSCRIPTION_PRODUCT_IDS, MOCK_MODE };

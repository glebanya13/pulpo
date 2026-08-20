const fs = require('node:fs');
const path = require('node:path');
const {
  SignedDataVerifier,
  Environment,
} = require('@apple/app-store-server-library');
const { google } = require('googleapis');
const {
  assertProductId,
  fallbackAmount,
  resolveSubscriptionExpiry,
} = require('./products');

const IOS_BUNDLE_ID = process.env.IOS_BUNDLE_ID || 'com.pulpo.app';
const ANDROID_PACKAGE = process.env.ANDROID_PACKAGE || 'com.pulpo.android';

/** @type {SignedDataVerifier[] | null} */
let appleVerifiers = null;

function loadAppleRootCerts() {
  const certDir = path.join(__dirname, 'certs');
  if (!fs.existsSync(certDir)) {
    return [];
  }
  return fs
    .readdirSync(certDir)
    .filter((name) => name.endsWith('.cer'))
    .map((name) => fs.readFileSync(path.join(certDir, name)));
}

function getAppleVerifiers() {
  if (appleVerifiers) return appleVerifiers;
  const roots = loadAppleRootCerts();
  if (!roots.length) {
    return [];
  }
  appleVerifiers = [
    new SignedDataVerifier(roots, true, Environment.SANDBOX, IOS_BUNDLE_ID),
    new SignedDataVerifier(roots, true, Environment.PRODUCTION, IOS_BUNDLE_ID),
  ];
  return appleVerifiers;
}

/**
 * @param {string} jws
 * @param {string} productId
 */
async function verifyApplePurchase(jws, productId) {
  assertProductId(productId);
  if (!jws || typeof jws !== 'string') {
    throw new Error('Missing iOS verification data');
  }

  const verifiers = getAppleVerifiers();
  /** @type {import('@apple/app-store-server-library').JWSTransactionDecodedPayload | null} */
  let decoded = null;

  for (const verifier of verifiers) {
    try {
      decoded = await verifier.verifyAndDecodeTransaction(jws);
      break;
    } catch {
      /* try next environment */
    }
  }

  if (!decoded) {
    throw new Error(
      'Unable to verify Apple transaction. Add Apple root certs to functions/certs/ and deploy.',
    );
  }

  if (decoded.productId && decoded.productId !== productId) {
    throw new Error('Apple productId mismatch');
  }

  // expiresDate from Apple already covers free trial (intro) and paid periods.
  const expiresAt = resolveSubscriptionExpiry({
    productId,
    expiresDateMs: decoded.expiresDate,
    offerType: decoded.offerType,
  });

  if (expiresAt.getTime() <= Date.now()) {
    throw new Error('Apple subscription expired');
  }

  return {
    transactionId: decoded.transactionId || decoded.originalTransactionId || '',
    originalTransactionId: decoded.originalTransactionId || decoded.transactionId || '',
    expiresAt,
    amount: fallbackAmount(productId),
    currency: 'EUR',
    isTrial: Number(decoded.offerType) === 1,
  };
}

function getAndroidPublisher() {
  const raw = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON;
  if (!raw) {
    throw new Error(
      'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON is not configured for Android verification',
    );
  }
  const credentials = JSON.parse(raw);
  const auth = new google.auth.GoogleAuth({
    credentials,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  return google.androidpublisher({ version: 'v3', auth });
}

/**
 * @param {string} purchaseToken
 * @param {string} productId
 */
async function verifyAndroidPurchase(purchaseToken, productId) {
  assertProductId(productId);
  if (!purchaseToken) {
    throw new Error('Missing Android purchase token');
  }

  const androidpublisher = getAndroidPublisher();
  const { data } = await androidpublisher.purchases.subscriptions.get({
    packageName: ANDROID_PACKAGE,
    subscriptionId: productId,
    token: purchaseToken,
  });

  const expiryMs = Number(data.expiryTimeMillis || 0);
  if (!expiryMs || expiryMs <= Date.now()) {
    throw new Error('Google Play subscription expired or invalid');
  }

  // paymentState: 0 pending, 1 received, 2 free trial, 3 deferred
  const paymentState = Number(data.paymentState ?? -1);
  if (paymentState === 0) {
    throw new Error('Google Play payment pending');
  }
  if (paymentState !== 1 && paymentState !== 2 && paymentState !== -1) {
    // Allow unknown/-1 for older responses; block deferred (3) and other unpaid states.
    if (paymentState === 3) {
      throw new Error('Google Play payment deferred');
    }
  }

  return {
    transactionId: data.orderId || purchaseToken.slice(0, 24),
    originalTransactionId: data.orderId || purchaseToken.slice(0, 24),
    expiresAt: new Date(expiryMs),
    amount: fallbackAmount(productId),
    currency: 'EUR',
    isTrial: paymentState === 2,
  };
}

/**
 * @param {{ platform: string, productId: string, verificationData: string }} input
 */
async function verifyStorePurchase(input) {
  const platform = String(input.platform || '').toLowerCase();
  const productId = String(input.productId || '');
  const verificationData = String(input.verificationData || '');

  if (platform === 'ios') {
    return verifyApplePurchase(verificationData, productId);
  }
  if (platform === 'android') {
    return verifyAndroidPurchase(verificationData, productId);
  }
  throw new Error(`Unsupported platform: ${platform}`);
}

module.exports = {
  verifyStorePurchase,
};

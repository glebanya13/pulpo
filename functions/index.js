const admin = require('firebase-admin');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { assertProductId } = require('./products');
const { verifyStorePurchase } = require('./verify');

admin.initializeApp();
const db = admin.firestore();

/**
 * @param {FirebaseFirestore.Firestore} firestore
 * @param {string} transactionId
 */
async function paymentExists(firestore, transactionId) {
  if (!transactionId) return false;
  const snap = await firestore
    .collection('payments')
    .where('transactionId', '==', transactionId)
    .limit(1)
    .get();
  return !snap.empty;
}

/**
 * @param {string} uid
 * @param {string} email
 * @param {string} productId
 * @param {{ transactionId: string, originalTransactionId: string, expiresAt: Date, amount: number, currency: string }} verified
 */
async function applyEntitlement(uid, email, productId, verified) {
  const expiresIso = verified.expiresAt.toISOString();
  const now = admin.firestore.FieldValue.serverTimestamp();

  await db.doc(`users/${uid}`).set(
    {
      email: email || null,
      pro: {
        entitled: true,
        source: 'iap',
        productId,
        grantedAt: new Date().toISOString(),
        expiresAt: expiresIso,
        revokedAt: null,
        transactionId: verified.transactionId,
        originalTransactionId: verified.originalTransactionId,
      },
      updatedAt: now,
    },
    { merge: true },
  );

  const exists = await paymentExists(db, verified.transactionId);
  if (!exists) {
    await db.collection('payments').add({
      uid,
      email: email || '',
      productId,
      amount: verified.amount,
      currency: verified.currency,
      source: 'iap',
      status: 'completed',
      transactionId: verified.transactionId,
      originalTransactionId: verified.originalTransactionId,
      createdAt: new Date().toISOString(),
    });
  }
}

exports.verifyPurchase = onCall({ region: 'europe-west1' }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in required');
  }

  const platform = String(request.data?.platform || '');
  const productId = String(request.data?.productId || '');
  const verificationData = String(request.data?.verificationData || '');

  try {
    assertProductId(productId);
  } catch (e) {
    throw new HttpsError('invalid-argument', e.message);
  }

  if (!verificationData) {
    throw new HttpsError('invalid-argument', 'verificationData required');
  }

  let verified;
  try {
    verified = await verifyStorePurchase({
      platform,
      productId,
      verificationData,
    });
  } catch (e) {
    throw new HttpsError('failed-precondition', e.message || 'Verification failed');
  }

  const uid = request.auth.uid;
  const email = request.auth.token.email || '';

  try {
    await applyEntitlement(uid, email, productId, verified);
  } catch (e) {
    throw new HttpsError('internal', e.message || 'Failed to save entitlement');
  }

  return {
    entitled: true,
    productId,
    expiresAt: verified.expiresAt.toISOString(),
    transactionId: verified.transactionId,
  };
});

exports.refreshEntitlement = onCall({ region: 'europe-west1' }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in required');
  }

  const snap = await db.doc(`users/${request.auth.uid}`).get();
  const pro = snap.data()?.pro;
  if (!pro || pro.source !== 'iap') {
    return { entitled: false, productId: null, expiresAt: null };
  }

  const expiresRaw = pro.expiresAt;
  const expiresAt = expiresRaw ? new Date(String(expiresRaw)) : null;
  const entitled =
    pro.entitled === true &&
    pro.source === 'iap' &&
    (!expiresAt || expiresAt.getTime() > Date.now());

  if (!entitled && pro.entitled === true) {
    await db.doc(`users/${request.auth.uid}`).set(
      {
        pro: {
          ...pro,
          entitled: false,
        },
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  return {
    entitled,
    productId: pro.productId || null,
    expiresAt: expiresAt ? expiresAt.toISOString() : null,
  };
});

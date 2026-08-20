/** @typedef {'pulpo_pro_mensual' | 'pulpo_pro_6_meses' | 'pulpo_pro_1anual' | 'pulpo_pro_monthly' | 'pulpo_pro_6months' | 'pulpo_pro_yearly'} ProductId */

/** Must match App Store Connect introductory offer (Free · 1 Week). */
const INTRO_TRIAL_DAYS = 7;

/** Apple offerType: 1 = introductory offer (free trial / intro pricing). */
const APPLE_OFFER_INTRODUCTORY = 1;

/** @type {Set<string>} */
const ALLOWED_PRODUCT_IDS = new Set([
  // App Store Connect (current)
  'pulpo_pro_mensual',
  'pulpo_pro_6_meses',
  'pulpo_pro_1anual',
  // Legacy IDs (existing grants / payments)
  'pulpo_pro_monthly',
  'pulpo_pro_6months',
  'pulpo_pro_yearly',
]);

/** @type {Record<string, { days: number, amount: number }>} */
const PRODUCT_FALLBACK = {
  pulpo_pro_mensual: { days: 30, amount: 3.99 },
  pulpo_pro_6_meses: { days: 183, amount: 14.99 },
  pulpo_pro_1anual: { days: 365, amount: 24.99 },
  pulpo_pro_monthly: { days: 30, amount: 3.99 },
  pulpo_pro_6months: { days: 183, amount: 14.99 },
  pulpo_pro_yearly: { days: 365, amount: 24.99 },
};

/**
 * @param {string} productId
 */
function assertProductId(productId) {
  if (!ALLOWED_PRODUCT_IDS.has(productId)) {
    throw new Error(`Unknown productId: ${productId}`);
  }
}

/**
 * @param {string} productId
 * @param {Date=} from
 * @param {number=} days
 */
function expiryFromDays(productId, from = new Date(), days) {
  const resolved =
    typeof days === 'number' && days > 0
      ? days
      : PRODUCT_FALLBACK[productId]?.days ?? 30;
  return new Date(from.getTime() + resolved * 86400000);
}

/**
 * @param {string} productId
 * @param {Date=} from
 */
function fallbackExpiry(productId, from = new Date()) {
  return expiryFromDays(productId, from);
}

/**
 * Resolve subscription end date for IAP verification.
 * Prefer store-provided expiry (covers free trial correctly).
 * If missing and Apple marks introductory offer → 7-day trial.
 * Otherwise fall back to full product period.
 *
 * @param {{
 *   productId: string,
 *   expiresDateMs?: number | null,
 *   offerType?: number | null,
 *   from?: Date,
 * }} input
 */
function resolveSubscriptionExpiry(input) {
  const productId = String(input.productId || '');
  assertProductId(productId);
  const from = input.from instanceof Date ? input.from : new Date();
  const expiresMs = Number(input.expiresDateMs || 0);
  if (expiresMs > 0) {
    return new Date(expiresMs);
  }
  if (Number(input.offerType) === APPLE_OFFER_INTRODUCTORY) {
    return expiryFromDays(productId, from, INTRO_TRIAL_DAYS);
  }
  return fallbackExpiry(productId, from);
}

/**
 * @param {string} productId
 */
function fallbackAmount(productId) {
  return PRODUCT_FALLBACK[productId]?.amount ?? 0;
}

module.exports = {
  ALLOWED_PRODUCT_IDS,
  INTRO_TRIAL_DAYS,
  APPLE_OFFER_INTRODUCTORY,
  assertProductId,
  fallbackExpiry,
  resolveSubscriptionExpiry,
  fallbackAmount,
};

/** @typedef {'pulpo_pro_monthly' | 'pulpo_pro_6months' | 'pulpo_pro_yearly'} ProductId */

/** @type {Set<string>} */
const ALLOWED_PRODUCT_IDS = new Set([
  'pulpo_pro_monthly',
  'pulpo_pro_6months',
  'pulpo_pro_yearly',
]);

/** @type {Record<string, { days: number, amount: number }>} */
const PRODUCT_FALLBACK = {
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
 */
function fallbackExpiry(productId, from = new Date()) {
  const meta = PRODUCT_FALLBACK[productId];
  const ms = from.getTime() + meta.days * 86400000;
  return new Date(ms);
}

/**
 * @param {string} productId
 */
function fallbackAmount(productId) {
  return PRODUCT_FALLBACK[productId]?.amount ?? 0;
}

module.exports = {
  ALLOWED_PRODUCT_IDS,
  assertProductId,
  fallbackExpiry,
  fallbackAmount,
};

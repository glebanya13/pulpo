const assert = require('node:assert/strict');
const { describe, it } = require('node:test');
const {
  assertProductId,
  fallbackExpiry,
  fallbackAmount,
  ALLOWED_PRODUCT_IDS,
} = require('../products');

describe('products', () => {
  it('allows known product ids', () => {
    for (const id of ALLOWED_PRODUCT_IDS) {
      assert.doesNotThrow(() => assertProductId(id));
    }
  });

  it('rejects unknown product ids', () => {
    assert.throws(() => assertProductId('fake_product'), /Unknown productId/);
  });

  it('fallback expiry adds days', () => {
    const from = new Date('2026-01-01T00:00:00.000Z');
    const expires = fallbackExpiry('pulpo_pro_monthly', from);
    assert.equal(expires.toISOString(), '2026-01-31T00:00:00.000Z');
  });

  it('fallback amounts match paywall', () => {
    assert.equal(fallbackAmount('pulpo_pro_monthly'), 3.99);
    assert.equal(fallbackAmount('pulpo_pro_6months'), 14.99);
    assert.equal(fallbackAmount('pulpo_pro_yearly'), 24.99);
  });
});

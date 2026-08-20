const assert = require('node:assert/strict');
const { describe, it } = require('node:test');
const {
  assertProductId,
  fallbackExpiry,
  fallbackAmount,
  resolveSubscriptionExpiry,
  INTRO_TRIAL_DAYS,
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
    const expires = fallbackExpiry('pulpo_pro_mensual', from);
    assert.equal(expires.toISOString(), '2026-01-31T00:00:00.000Z');
  });

  it('fallback amounts match paywall', () => {
    assert.equal(fallbackAmount('pulpo_pro_mensual'), 3.99);
    assert.equal(fallbackAmount('pulpo_pro_6_meses'), 14.99);
    assert.equal(fallbackAmount('pulpo_pro_1anual'), 24.99);
  });
});

describe('resolveSubscriptionExpiry (trial)', () => {
  const from = new Date('2026-08-20T12:00:00.000Z');

  it('uses Apple expiresDate when present (trial or paid)', () => {
    const trialEnd = Date.parse('2026-08-27T12:00:00.000Z');
    const expires = resolveSubscriptionExpiry({
      productId: 'pulpo_pro_1anual',
      expiresDateMs: trialEnd,
      offerType: 1,
      from,
    });
    assert.equal(expires.toISOString(), '2026-08-27T12:00:00.000Z');
  });

  it('falls back to 7-day intro when offerType is introductory and no expiresDate', () => {
    const expires = resolveSubscriptionExpiry({
      productId: 'pulpo_pro_mensual',
      expiresDateMs: null,
      offerType: 1,
      from,
    });
    const expected = new Date(from.getTime() + INTRO_TRIAL_DAYS * 86400000);
    assert.equal(expires.toISOString(), expected.toISOString());
  });

  it('falls back to full product period when not intro and no expiresDate', () => {
    const expires = resolveSubscriptionExpiry({
      productId: 'pulpo_pro_mensual',
      expiresDateMs: 0,
      offerType: null,
      from,
    });
    assert.equal(expires.toISOString(), '2026-09-19T12:00:00.000Z');
  });

  it('rejects unknown product ids', () => {
    assert.throws(
      () =>
        resolveSubscriptionExpiry({
          productId: 'nope',
          expiresDateMs: Date.now() + 86400000,
        }),
      /Unknown productId/,
    );
  });
});

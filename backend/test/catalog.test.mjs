import { test } from 'node:test';
import assert from 'node:assert/strict';
import { api, formatPrice, products } from '../src/catalog.mjs';

test('prices are formatted in dollars', () => {
  assert.equal(formatPrice(1800), '$18.00');
  assert.equal(formatPrice(5), '$0.05');
});

test('v1 lists every product with its price', () => {
  const v1 = api('0.0.0-test')['api/v1/price.json'];
  assert.equal(v1.items.length, products.length);
  assert.deepEqual(v1.items[0], { sku: 'mug-01', name: 'Enamel mug', price: '$18.00' });
});

test('the API carries the build version', () => {
  assert.equal(api('1.2.3')['api/v1/price.json'].version, '1.2.3');
});

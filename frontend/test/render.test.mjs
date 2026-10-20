import { test } from 'node:test';
import assert from 'node:assert/strict';
import { render, PRICE_API } from '../src/render.mjs';

test('renders one row per item', () => {
  const html = render({ version: '1.0.0', items: [{ name: 'A', price: '$1.00' }, { name: 'B', price: '$2.00' }] });
  assert.equal((html.match(/<li>/g) ?? []).length, 2);
  assert.match(html, /catalog 1\.0\.0/);
});

test('reads the price API', () => {
  assert.match(PRICE_API, /^api\/v\d+\/price\.json$/);
});

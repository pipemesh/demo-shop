// The shop's catalog and the price API it publishes as static JSON.
export const products = [
  { sku: 'mug-01', name: 'Enamel mug', cents: 1800 },
  { sku: 'tee-02', name: 'Logo tee', cents: 2900 },
  { sku: 'cap-03', name: 'Field cap', cents: 2600 },
];

export const TAX_RATE = 0.08;

export function formatPrice(cents) {
  return `$${(cents / 100).toFixed(2)}`;
}

// Every file the API serves, by path, as plain objects.
export function api(version) {
  return {
    'api/v1/price.json': {
      version,
      items: products.map((p) => ({ sku: p.sku, name: p.name, price: formatPrice(p.cents) })),
    },
    // v2 adds the currency and the tax each price carries.
    'api/v2/price.json': {
      version,
      currency: 'USD',
      items: products.map((p) => ({
        sku: p.sku, name: p.name, price: formatPrice(p.cents), tax: formatPrice(Math.round(p.cents * TAX_RATE)),
      })),
    },
  };
}

// The shop's catalog and the price API it publishes as static JSON.
export const products = [
  { sku: 'mug-01', name: 'Enamel mug', cents: 1800 },
  { sku: 'tee-02', name: 'Logo tee', cents: 2900 },
  { sku: 'cap-03', name: 'Field cap', cents: 2400 },
];

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
  };
}

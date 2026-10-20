// Renders the price list. Pure, so it is testable and the page can be
// previewed before anything deploys.
export const PRICE_API = 'api/v1/price.json';

export function render(data) {
  const rows = data.items.map((i) => `<li><span>${i.name}</span><b>${i.price}</b></li>`).join('');
  return `<ul class="prices">${rows}</ul><p class="version">catalog ${data.version}</p>`;
}

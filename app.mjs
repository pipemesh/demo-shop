import { PRICE_API, render } from './render.mjs';

const main = document.querySelector('main');
try {
  const res = await fetch(PRICE_API);
  if (!res.ok) throw new Error(`${PRICE_API}: ${res.status}`);
  main.innerHTML = render(await res.json());
} catch (e) {
  main.innerHTML = `<p class="error">The shop is unavailable: ${e.message}</p>`;
}

// Asks the live site the question a customer would: does the page load, and
// does the price API it calls answer? Run after both halves deployed.
// GitHub Pages serves a push a little after it lands, so the check keeps
// asking for up to two minutes before it calls the shop broken.
const base = (process.argv[2] ?? process.env.SITE_URL ?? '').replace(/\/?$/, '/');
if (!base) { console.error('usage: check.mjs <site url>'); process.exit(2); }

async function ask() {
  const page = await fetch(base + 'index.html', { cache: 'no-store' });
  if (!page.ok) return `${base}: ${page.status}`;
  const app = await (await fetch(base + 'render.mjs', { cache: 'no-store' })).text();
  const api = app.match(/PRICE_API = '([^']+)'/)?.[1];
  if (!api) return 'the site names no price API';
  const res = await fetch(base + api, { cache: 'no-store' });
  if (!res.ok) return `the site calls ${api}, which answers ${res.status}: the shop is broken`;
  const data = await res.json();
  console.log(`${base} serves ${data.items.length} prices from ${api} (catalog ${data.version})`);
  return null;
}

const deadline = Date.now() + 120_000;
for (;;) {
  const problem = await ask();
  if (!problem) process.exit(0);
  if (Date.now() > deadline) { console.error(problem); process.exit(1); }
  console.log(`${problem}; asking again in 10 s`);
  await new Promise((r) => setTimeout(r, 10_000));
}

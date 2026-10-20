// Asks the live site the question a customer would: does the page load, and
// does the price API it calls answer? Run after both halves deployed.
const base = (process.argv[2] ?? process.env.SITE_URL ?? '').replace(/\/?$/, '/');
if (!base) { console.error('usage: check.mjs <site url>'); process.exit(2); }

const page = await fetch(base + 'index.html');
if (!page.ok) { console.error(`${base}: ${page.status}`); process.exit(1); }
const app = await (await fetch(base + 'render.mjs')).text();
const api = app.match(/PRICE_API = '([^']+)'/)?.[1];
if (!api) { console.error('the site names no price API'); process.exit(1); }
const res = await fetch(base + api);
if (!res.ok) { console.error(`the site calls ${api}, which answers ${res.status}: the shop is broken`); process.exit(1); }
const data = await res.json();
console.log(`${base} serves ${data.items.length} prices from ${api} (catalog ${data.version})`);

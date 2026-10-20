// Builds the site into dist/site (copied as is: no bundler, no deps), packs
// it into dist/site.tar, and draws dist/preview.svg, a picture of the page
// for the Reports tab.
import { mkdirSync, copyFileSync, writeFileSync, rmSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { render } from './render.mjs';

const root = new URL('..', import.meta.url).pathname;
const out = join(root, 'dist');
rmSync(out, { recursive: true, force: true });
mkdirSync(join(out, 'site'), { recursive: true });
for (const f of ['index.html', 'app.mjs', 'render.mjs']) copyFileSync(join(root, 'src', f), join(out, 'site', f));

const sample = { version: 'preview', items: [{ name: 'Enamel mug', price: '$18.00' }, { name: 'Logo tee', price: '$29.00' }, { name: 'Field cap', price: '$24.00' }] };
const html = readFileSync(join(root, 'src', 'index.html'), 'utf8');
const footer = (html.match(/<footer>(.*?)<\/footer>/s) ?? [, ''])[1].replace(/<[^>]+>/g, '').trim();
const lines = render(sample).match(/<li>.*?<\/li>/g).map((li) => li.replace(/<[^>]+>/g, '|').split('|').filter(Boolean));
let y = 90;
const rows = lines.map(([name, price]) => {
  const r = `<text x="40" y="${y}">${name}</text><text x="360" y="${y}" text-anchor="end" font-weight="600">${price}</text><line x1="40" y1="${y + 12}" x2="360" y2="${y + 12}" stroke="#d0d7de"/>`;
  y += 36; return r;
}).join('');
writeFileSync(join(out, 'preview.svg'), `<svg xmlns="http://www.w3.org/2000/svg" width="400" height="${y + 60}" font-family="system-ui,sans-serif" font-size="14" fill="#1f2328"><rect width="400" height="${y + 60}" fill="#fff"/><text x="40" y="50" font-size="20">demo-shop</text>${rows}<text x="40" y="${y + 10}" font-size="12" fill="#656d76">catalog ${sample.version}</text><text x="40" y="${y + 40}" font-size="12" fill="#656d76">${footer}</text></svg>\n`);
console.log(`site written to ${out}/site`);

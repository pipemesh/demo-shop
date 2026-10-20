// Writes the API's files under dist/api and packs them into dist/api.tar.
import { mkdirSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { api } from './catalog.mjs';

const root = new URL('..', import.meta.url).pathname;
const version = readFileSync(join(root, 'VERSION'), 'utf8').trim();
const out = join(root, 'dist');
rmSync(out, { recursive: true, force: true });
for (const [path, body] of Object.entries(api(version))) {
  mkdirSync(join(out, dirname(path)), { recursive: true });
  writeFileSync(join(out, path), JSON.stringify(body, null, 2) + '\n');
}
console.log(`api ${version} written to ${out}/api`);

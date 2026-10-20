// Packs a directory into a plain ustar archive with fixed metadata, so the
// same files always give the same bytes: sorted names, mtime 0, uid/gid 0.
// Node has no tar module and the system tar differs by platform; a build
// that is not byte-reproducible would give every deploy a new artifact.
import { readdirSync, readFileSync, statSync, writeFileSync, mkdirSync } from 'node:fs';
import { join, relative, dirname } from 'node:path';

const [dir, out] = process.argv.slice(2);
if (!dir || !out) { console.error('usage: pack.mjs <dir> <out.tar>'); process.exit(2); }

function* walk(d) {
  for (const name of readdirSync(d).sort()) {
    const p = join(d, name);
    if (statSync(p).isDirectory()) yield* walk(p); else yield p;
  }
}
function header(name, size) {
  const h = Buffer.alloc(512);
  h.write(name, 0, 100);
  h.write('0000644\0', 100); h.write('0000000\0', 108); h.write('0000000\0', 116);
  h.write(size.toString(8).padStart(11, '0') + '\0', 124);
  h.write('00000000000\0', 136);           // mtime 0
  h.write('        ', 148);                 // checksum placeholder
  h.write('0', 156); h.write('ustar\0', 257); h.write('00', 263);
  let sum = 0; for (const b of h) sum += b;
  h.write(sum.toString(8).padStart(6, '0') + '\0 ', 148);
  return h;
}
const parts = [];
for (const file of walk(dir)) {
  const data = readFileSync(file);
  parts.push(header(relative(dir, file), data.length), data);
  const pad = (512 - (data.length % 512)) % 512;
  if (pad) parts.push(Buffer.alloc(pad));
}
parts.push(Buffer.alloc(1024));
mkdirSync(dirname(out), { recursive: true });
writeFileSync(out, Buffer.concat(parts));
console.log(`packed ${dir} -> ${out}`);

// A node:test reporter that writes the run as a small HTML site: the
// verdict, a row per test, each failure's message. A directory holding an
// index.html is shown as a site in the job panel's Reports tab.
export default async function* html(source) {
  const rows = [];
  for await (const { type, data } of source) {
    if ((type !== 'test:pass' && type !== 'test:fail') || data.details?.type === 'suite') continue;
    rows.push({
      name: data.name, file: (data.file ?? '').split('/').pop(),
      state: type === 'test:fail' ? 'fail' : 'pass',
      ms: data.details?.duration_ms ?? 0,
      error: String(data.details?.error?.cause?.message ?? data.details?.error?.message ?? ''),
    });
  }
  const failed = rows.filter((r) => r.state === 'fail');
  const esc = (s) => s.replace(/[&<>]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]));
  yield `<!doctype html><meta charset="utf-8"><title>Tests</title>
<style>body{font:14px/1.5 system-ui,sans-serif;margin:24px;color:#1f2328}h1{font-size:18px}
table{border-collapse:collapse}td,th{padding:4px 12px;border-bottom:1px solid #d0d7de;text-align:left}
.pass{color:#1a7f37}.fail{color:#cf222e}pre{background:#f6f8fa;padding:12px;border-radius:6px}</style>
<h1>${failed.length ? `❌ ${failed.length} of ${rows.length} tests failed` : `✅ ${rows.length} tests passed`}</h1>
<table><tr><th></th><th>Test</th><th>File</th><th>Time</th></tr>
`;
  for (const r of rows) yield `<tr><td class="${r.state}">${r.state === 'pass' ? '✓' : '✗'}</td><td>${esc(r.name)}</td><td>${esc(r.file)}</td><td>${r.ms.toFixed(1)} ms</td></tr>\n`;
  yield '</table>\n';
  for (const r of failed) yield `<h2 class="fail">${esc(r.name)}</h2><pre>${esc(r.error.trim())}</pre>\n`;
}

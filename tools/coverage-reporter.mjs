// A node:test reporter that writes the coverage summary node reports with
// --experimental-test-coverage as a Markdown document, one row per file.
export default async function* coverage(source) {
  let summary;
  for await (const { type, data } of source) if (type === 'test:coverage') summary = data.summary;
  if (!summary) { yield '# Coverage\n\nNo coverage was collected.\n'; return; }
  const pct = (n) => `${n.toFixed(1)}%`;
  const t = summary.totals;
  yield `# Coverage: ${pct(t.coveredLinePercent)} of lines\n\n`;
  yield '| File | Lines | Branches | Functions |\n|---|---:|---:|---:|\n';
  for (const f of summary.files) {
    const name = f.path.split('/').slice(-2).join('/');
    yield `| \`${name}\` | ${pct(f.coveredLinePercent)} | ${pct(f.coveredBranchPercent)} | ${pct(f.coveredFunctionPercent)} |\n`;
  }
  yield `| **all** | **${pct(t.coveredLinePercent)}** | **${pct(t.coveredBranchPercent)}** | **${pct(t.coveredFunctionPercent)}** |\n`;
}

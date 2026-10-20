#!/usr/bin/env bash
# Builds the site into dist/site, packs dist/site.tar, draws dist/preview.svg.
set -euo pipefail
cd "$(dirname "$0")"
node src/build.mjs
node ../tools/pack.mjs dist/site dist/site.tar

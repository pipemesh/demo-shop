#!/usr/bin/env bash
# Builds the backend: the API's JSON files, packed into dist/api.tar.
set -euo pipefail
cd "$(dirname "$0")"
node src/build.mjs
node ../tools/pack.mjs dist/api dist/api.tar

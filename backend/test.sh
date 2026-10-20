#!/usr/bin/env bash
# Runs the backend's tests and writes the reports the job panel shows:
# build/reports/tests/index.html (a site) and build/reports/coverage.md.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build/reports/tests
node --test --experimental-test-coverage \
  --test-reporter=spec --test-reporter-destination=stdout \
  --test-reporter=../tools/html-reporter.mjs --test-reporter-destination=build/reports/tests/index.html \
  --test-reporter=../tools/coverage-reporter.mjs --test-reporter-destination=build/reports/coverage.md \
  'test/*.test.mjs'

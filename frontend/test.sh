#!/usr/bin/env bash
# Runs the frontend's tests; the report lands in build/reports/tests.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build/reports/tests
node --test --test-reporter=spec --test-reporter-destination=stdout \
  --test-reporter=../tools/html-reporter.mjs --test-reporter-destination=build/reports/tests/index.html \
  'test/*.test.mjs'

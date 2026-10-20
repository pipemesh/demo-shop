#!/usr/bin/env bash
# Puts the deploy key a Pipemesh job receives as $PAGES_DEPLOY_KEY where
# git finds it. GitHub Actions jobs push with the run's token instead.
set -euo pipefail
[ -n "${PAGES_DEPLOY_KEY:-}" ] || exit 0
mkdir -p ~/.ssh && chmod 700 ~/.ssh
printf '%s\n' "$PAGES_DEPLOY_KEY" > ~/.ssh/deploy_key && chmod 600 ~/.ssh/deploy_key
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null
echo "IdentityFile ~/.ssh/deploy_key" >> ~/.ssh/config

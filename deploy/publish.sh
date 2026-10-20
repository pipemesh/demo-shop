#!/usr/bin/env bash
# Publishes an artifact to the site: the repository's GitHub Pages branch.
#   publish.sh api  dist/api.tar    replaces the site's api/ directory
#   publish.sh site dist/site.tar   replaces everything but api/
# The branch is gh-pages at $PAGES_REMOTE. A push the branch refuses (the
# other half published first) is retried from a fresh clone.
set -euo pipefail
what=$1; tar=$2
: "${PAGES_REMOTE:?the git remote of the site (PAGES_REMOTE)}"
[ -f "$tar" ] || { echo "no artifact at $tar"; exit 1; }

work=$(mktemp -d)
mkdir -p "$work/in" && tar -xf "$tar" -C "$work/in"

if [ "$what" = api ]; then
  version=$(sed -n 's/^ *"version": "\(.*\)",*$/\1/p' "$work/in/v1/price.json" | head -1)
  echo "api version $version"
  case $version in *-bad*) echo "refusing to deploy a pre-release build ($version)"; exit 1;; esac
fi

publish() (
  rm -rf "$work/site"
  if ! git clone -q --depth 1 --branch gh-pages "$PAGES_REMOTE" "$work/site" 2>/dev/null; then
    git init -q "$work/site" && git -C "$work/site" checkout -q -b gh-pages
  fi
  cd "$work/site"
  if [ "$what" = api ]; then
    rm -rf api && mkdir api && cp -R "$work/in/." api/
  else
    find . -mindepth 1 -maxdepth 1 ! -name api ! -name .git -exec rm -rf {} +
    cp -R "$work/in/." .
    touch .nojekyll
  fi
  git add -A
  if git diff --cached --quiet; then echo "the site already has this $what"; exit 0; fi
  git -c user.name=pipemesh -c user.email=noreply@pipemesh.io commit -q -m "$what: ${CI_COMMIT_SHORT_SHA:-$(date -u +%FT%TZ)}"
  git push -q "$PAGES_REMOTE" gh-pages 2>&1 | grep -v '^hint:' || true
  git ls-remote --exit-code "$PAGES_REMOTE" gh-pages | grep -q "^$(git rev-parse HEAD)"
)

for attempt in 1 2 3 4 5; do
  # Each attempt starts from a fresh clone, in a subshell so a deleted
  # working directory never follows into the next one.
  if publish; then echo "$what published"; exit 0; fi
  echo "push refused, retrying ($attempt)"; sleep $((attempt * 2))
done
echo "could not publish $what"; exit 1

#!/usr/bin/env bash
# The takes: the commits the demo video pushes one by one, as stacked
# branches, rebuilt from main and gha by `scripts/takes.sh build`.
# During a recording, `scripts/takes.sh push c1` force-pushes a take onto
# main (the stack is linear, so each push after the previous is a fast-forward).
#
#   Pipemesh half (stacked on main):        GitHub Actions half (stacked on gha):
#     c1   API: add /v2/price (deploy fails)   g0  README: how to run locally (every job runs)
#     c2   Site: price from /v2/price          g1  Workflows: run on the half that changed
#     c3   Site: footer                        c1  c2  c3  fix1  c5
#     fix1 Release 1.4.1
#     c4   README: how to run locally
#     s1 s2 s3  three quick price changes (supersede)
#     c5   Build: version the archive name (the producer check fails)
#     fix2 Build: the archive name the deploy expects
#     c6   Builds move into a workflow shared with PR checks
#     c7   README: where the shop is (the workflow job reuses as one)
set -euo pipefail
cd "$(dirname "$0")/.."
cmd=${1:-}; shift || true

commit() { git add -A && git -c commit.gpgsign=false commit -q -m "$1" && git branch -f "take/$2" && echo "take/$2  $1"; }

# --- edits, each a function; they run on the stacked tree in order
c1() {
  echo 1.4.0-bad > backend/VERSION
  python3 - <<'PY'
import re
p='backend/src/catalog.mjs'; s=open(p).read()
s=s.replace("""export function formatPrice(cents) {""","""export const TAX_RATE = 0.08;

export function formatPrice(cents) {""")
s=s.replace("""      items: products.map((p) => ({ sku: p.sku, name: p.name, price: formatPrice(p.cents) })),
    },
  };""","""      items: products.map((p) => ({ sku: p.sku, name: p.name, price: formatPrice(p.cents) })),
    },
    // v2 adds the currency and the tax each price carries.
    'api/v2/price.json': {
      version,
      currency: 'USD',
      items: products.map((p) => ({
        sku: p.sku, name: p.name, price: formatPrice(p.cents), tax: formatPrice(Math.round(p.cents * TAX_RATE)),
      })),
    },
  };""")
open(p,'w').write(s)
p='backend/test/catalog.test.mjs'; s=open(p).read()
s+="""
test('v2 adds the tax per item', () => {
  const v2 = api('0.0.0-test')['api/v2/price.json'];
  assert.equal(v2.currency, 'USD');
  assert.equal(v2.items[0].tax, '$1.44');
});
"""
open(p,'w').write(s)
PY
}
c2() {
  python3 - <<'PY'
p='frontend/src/render.mjs'; s=open(p).read()
s=s.replace("export const PRICE_API = 'api/v1/price.json';","export const PRICE_API = 'api/v2/price.json';")
s=s.replace("""  const rows = data.items.map((i) => `<li><span>${i.name}</span><b>${i.price}</b></li>`).join('');""",
"""  const rows = data.items.map((i) => `<li><span>${i.name}</span><b>${i.price} <small>+ ${i.tax} tax</small></b></li>`).join('');""")
open(p,'w').write(s)
p='frontend/test/render.test.mjs'; s=open(p).read()
s=s.replace("[{ name: 'A', price: '$1.00' }, { name: 'B', price: '$2.00' }]","[{ name: 'A', price: '$1.00', tax: '$0.08' }, { name: 'B', price: '$2.00', tax: '$0.16' }]")
s=s.replace("  assert.match(html, /catalog 1\\.0\\.0/);","  assert.match(html, /catalog 1\\.0\\.0/);\n  assert.match(html, /\\$0\\.08 tax/);")
open(p,'w').write(s)
p='frontend/src/build.mjs'; s=open(p).read()
s=s.replace("items: [{ name: 'Enamel mug', price: '$18.00' }, { name: 'Logo tee', price: '$29.00' }, { name: 'Field cap', price: '$24.00' }]",
            "items: [{ name: 'Enamel mug', price: '$18.00', tax: '$1.44' }, { name: 'Logo tee', price: '$29.00', tax: '$2.32' }, { name: 'Field cap', price: '$24.00', tax: '$1.92' }]")
open(p,'w').write(s)
PY
}
c3() { sed -i.bak 's#^<script type="module" src="app.mjs"></script>#<footer>Prices include tax where shown. Open source demo by Pipemesh.</footer>\n<script type="module" src="app.mjs"></script>#' frontend/src/index.html && rm frontend/src/index.html.bak; }
fix1() { echo 1.4.1 > backend/VERSION; }
c4() { printf '\n## Run it locally\n\n```bash\nbackend/test.sh && backend/build.sh\nfrontend/test.sh && frontend/build.sh\n```\n\nThe API lands in `backend/dist/api`, the site in `frontend/dist/site`.\n' >> README.md; }
price() { sed -i.bak "s/{ sku: 'cap-03', name: 'Field cap', cents: [0-9]* }/{ sku: 'cap-03', name: 'Field cap', cents: $1 }/" backend/src/catalog.mjs && rm backend/src/catalog.mjs.bak; }
s1() { price 2500; }
s2() { price 2600; }
s3() { price 2700; }
c5() { sed -i.bak 's#node ../tools/pack.mjs dist/api dist/api.tar#node ../tools/pack.mjs dist/api "dist/api-$(cat VERSION).tar"#' backend/build.sh && rm backend/build.sh.bak; }
fix2() { sed -i.bak 's#node ../tools/pack.mjs dist/api "dist/api-$(cat VERSION).tar"#node ../tools/pack.mjs dist/api dist/api.tar#' backend/build.sh && rm backend/build.sh.bak; }
c6() {
  python3 - <<'PY'
p='pipemesh.yaml'; s=open(p).read()
head, rest = s.split("    build_backend:\n",1)
builds, rest = rest.split("    # A deploy checks out only the deploy scripts",1)
builds = "    build_backend:\n" + builds
# the two builds become a workflow body at the root
body = "builds:\n  type: workflow\n  stages:\n    - build\n  jobs:\n" + builds.rstrip() + "\n\n"
head = head.replace("pipeline:\n  type: pipeline\n", body + "pipeline:\n  type: pipeline\n")
head = head.replace("""    # A build reads its half and the shared tools, tests it, and packs the
    # API's files. Same files in, same bytes out: an identical artifact is
    # reused, and a deploy that already shipped it has nothing to do.
""","""    # The builds run as one workflow job: a group of builds and tests that
    # deploy nothing, waited for as one. It is the same body the pull
    # request checks run (pipemesh.workflows.checks below).
    build:
      job_type: workflow
      stage: build
      body: !ref builds

""")
rest = "    # A deploy checks out only the deploy scripts" + rest
rest = rest.replace("API: build_backend/api","API: build/build_backend/api").replace("SITE: build_frontend/site","SITE: build/build_frontend/site")
rest = rest.replace("""pipemesh:
  pipelines:
    pipeline: !ref pipeline
""","""pipemesh:
  pipelines:
    pipeline: !ref pipeline
  workflows:
    # The same builds, per pull request.
    checks:
      body: !ref builds
      on: pull_request
    # Every night, ask the live shop whether it still answers.
    nightly:
      body: !include .pipemesh/nightly.yaml
      on: schedule
      cron: "0 3 * * *"
""")
open(p,'w').write(head+rest)
PY
}
c7() { printf '\nThe shop is live at https://pipemesh.github.io/demo-shop/ and its board at https://pipemesh.io/github.com/pipemesh/demo-shop/-/pipeline.\n' >> README.md; }
g0() { c4; }
g1() { sed -i.bak "s#^    branches: \[main\]\$#    branches: [main]\n    paths: ['HALF/**', 'tools/**', 'deploy/**']#" .github/workflows/deploy-backend.yml .github/workflows/deploy-frontend.yml && sed -i.bak 's#HALF#backend#' .github/workflows/deploy-backend.yml && sed -i.bak 's#HALF#frontend#' .github/workflows/deploy-frontend.yml && rm .github/workflows/*.bak; }

build() {
  git diff --quiet && git diff --cached --quiet || { echo "commit or drop your changes first"; exit 1; }
  start=$(git rev-parse --abbrev-ref HEAD)
  git checkout -q main
  c1; commit "API: add /v2/price" c1
  c2; commit "Site: price from /v2/price" c2
  c3; commit "Site: footer" c3
  fix1; commit "Release 1.4.1" fix1
  c4; commit "README: how to run locally" c4
  s1; commit "Field cap: 25.00" s1
  s2; commit "Field cap: 26.00" s2
  s3; commit "Field cap: 27.00" s3
  c5; commit "Build: version the archive name" c5
  fix2; commit "Build: the archive name the deploy expects" fix2
  c6; commit "Builds move into a workflow shared with PR checks" c6
  c7; commit "README: where the shop is" c7
  git checkout -q main
  # the GitHub Actions half: no definition, the two workflows without path filters
  git branch -f gha main && git checkout -q gha
  mkdir -p .github/workflows && cp scripts/gha/*.yml .github/workflows/ && git rm -q pipemesh.yaml && git rm -rq .pipemesh
  sed -i.bak "/^    paths:/d" .github/workflows/*.yml && rm .github/workflows/*.bak
  git add -A && git -c commit.gpgsign=false commit -q -m "The shop on GitHub Actions" && echo "gha  The shop on GitHub Actions"
  g0; commit "README: how to run locally" g0
  g1; commit "Workflows: run on the half that changed" g1
  c1; commit "API: add /v2/price" gc1
  c2; commit "Site: price from /v2/price" gc2
  c3; commit "Site: footer" gc3
  fix1; commit "Release 1.4.1" gfix1
  c5; commit "Build: version the archive name" gc5
  git checkout -q "$start"
}
push() { git push -f origin "take/$1:main"; }
list() { git branch --list 'take/*' --format='%(refname:short)  %(subject)'; }
case $cmd in build) build;; push) push "$@";; list) list;; *) echo "usage: takes.sh build | push <take> | list"; exit 2;; esac

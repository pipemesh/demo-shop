# demo-shop

A shop with a backend and a frontend in one repository, built for a
[Pipemesh](https://pipemesh.io) demo video: the same code runs once on
GitHub Actions with path filters, and once on one Pipemesh pipeline.

- `backend/` publishes the price API as static JSON (`api/v1/price.json`),
  packed into `dist/api.tar`. Its tests write an HTML report and a
  coverage summary for the job panel.
- `frontend/` is the site that calls the API, packed into `dist/site.tar`,
  with the built site and a drawn preview as reports.
- `deploy/publish.sh` ships either half to this repository's GitHub Pages
  branch; `smoke/check.mjs` asks the live shop whether the page loads and
  the API it calls answers.
- `pipemesh.yaml` is the pipeline; `scripts/gha/` the two Actions
  workflows the `gha` branch runs instead.

Builds are byte-reproducible (`tools/pack.mjs` writes a tar with fixed
metadata), so an unchanged half gives the same artifact and its deploy
has nothing to do.

## The takes

`scripts/takes.sh build` rebuilds the commits the video pushes, as
stacked branches `take/*`; `scripts/takes.sh push c1` puts one on `main`.
The script lists them. `backend/deploy` refuses a version ending in
`-bad`: that is how the backend deploy fails on cue.

## Run it locally

```bash
backend/test.sh && backend/build.sh
frontend/test.sh && frontend/build.sh
```

The API lands in `backend/dist/api`, the site in `frontend/dist/site`.

The shop is live at https://pipemesh.github.io/demo-shop/ and its board at https://pipemesh.io/github.com/pipemesh/demo-shop/-/pipeline.

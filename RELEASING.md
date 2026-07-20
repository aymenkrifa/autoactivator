# Releasing

AutoActivator ships as source — installs happen via `setup.sh` (`git clone` /
`git pull`), so a release is a **git tag + a GitHub Release**, with no build
artifacts. The `autoactivator version` command derives its output from
`git describe --tags`, so nothing in the code hardcodes the version.

## Versioning

- Tags use the **`v` prefix** and semver: `v0.3.0`, `v0.4.0`, `v1.0.0`.
- Stay pre-1.0 (`v0.x`) until the behavior (venv priority, `$AUTOACTIVATOR_VENV_NAME`,
  `update` / `uninstall --purge` semantics) is frozen for a 1.0 promise.
- The old `0.1.0` / `0.2.0` tags predate this convention — leave them as-is;
  don't retag history.

## Before tagging — bump the version in the docs

Two files reference the version and must be updated in the release commit:

1. **`docs/index.html`**
   - The header badge default: `<a class="ver" id="ver" ...>vX.Y.Z</a>`
     (it self-corrects from the GitHub API at runtime, but this is the value
     search engines and no-JS visitors see).
   - The benchmark table's last column header: `<th>vX.Y.Z</th>`.
2. **`README.md`**
   - The benchmark table's last column header: `| ... | vX.Y.Z |`.

## Cut the release

```sh
# after the docs bump is committed and pushed to main
git tag -a vX.Y.Z -m "AutoActivator vX.Y.Z"
git push origin vX.Y.Z

gh release create vX.Y.Z \
  --title "AutoActivator vX.Y.Z" \
  --notes-file notes.md \
  --latest
```

## Release notes style

Open with one sentence of context, then use `##` sections as they apply —
**New**, **Fixes & correctness**, **Performance**, **Quality** — followed by an
**Install** block and a **Full changelog** compare link:

```md
Since vA.B.C, <one-line summary>.

## New
- ...

## Fixes & correctness
- ...

## Install

​```sh
curl -sSL https://autoactivator.aymenkrifa.com/setup.sh | bash -s zsh
​```

**Full changelog:** https://github.com/aymenkrifa/autoactivator/compare/vA.B.C...vX.Y.Z
```

## Notes

- CI guards that `docs/setup.sh` stays byte-identical to `setup.sh` (the branded
  `autoactivator.aymenkrifa.com/setup.sh` install URL is served from `docs/`).
  If you edit `setup.sh`, copy it to `docs/setup.sh` in the same commit.
- The site publishes from `main` `/docs` via GitHub Pages; pushing to `main`
  redeploys it.

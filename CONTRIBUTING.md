# Contributing to polyglotSQL

## Development setup

You need R (\>= 4.2), Rust (cargo + rustc \>= 1.88) and the usual R dev
packages (`devtools`, `rextendr`, `testthat`, `pkgdown`).

``` r

devtools::document()   # regenerates Rd + NAMESPACE (and Rust wrappers on build)
devtools::test()
devtools::check()
```

The Rust sources live in `src/rust/`. After changing exported
`#[extendr]` functions, rebuild so `R/extendr-wrappers.R` is regenerated
(it is written by `cargo run --bin document` during the build).

Run `cargo fmt` and `cargo clippy --lib` inside `src/rust/` before
pushing; CI enforces both.

## Updating the embedded polyglot-sql crate

``` sh
tools/update-vendor.sh <new-version>
```

The script bumps the dependency in `src/rust/Cargo.toml`, refreshes
`Cargo.lock`, re-vendors all crates into `src/rust/vendor.tar.xz` (the
archive used for offline builds), and regenerates `inst/COPYRIGHTS`.
Then:

1.  update `Config/polyglotSQL/upstream` in `DESCRIPTION`;
2.  run the test suite
    ([`devtools::test()`](https://devtools.r-lib.org/reference/test.html)),
    which asserts the linked crate version matches `DESCRIPTION`;
3.  mention the upgrade in `NEWS.md`.

## Publishing the pkgdown site (GitHub Pages)

The `pkgdown` workflow builds the site on every push to `main` (or
manually via *Actions → pkgdown → Run workflow*) and pushes the rendered
site to the `gh-pages` branch using only the repository `GITHUB_TOKEN`.

To enable it once per repository: **Settings → Pages → Build and
deployment → Source: “Deploy from a branch” → Branch: `gh-pages` /
`/ (root)`**. The first workflow run creates the branch automatically.

Local preview:
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
then open `docs/index.html`.

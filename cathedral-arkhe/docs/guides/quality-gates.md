# Quality Gates & ASI-Grade Verification v2.0

## Setup Tools
Install the necessary quality gates tools:
```bash
cargo install cargo-llvm-cov cargo-insta cargo-deny cargo-audit cargo-semver-checks
```

## Running `cargo xtask`

The CI and Pre-commit pipelines are managed via `cargo xtask`. An alias is provided so you can run:

```bash
cargo xtask pre-commit
```
This command runs:
- `cargo fmt --check`
- `cargo check`
- `cargo clippy`
- `cargo deny check`
- `cargo audit`
- `cargo llvm-cov`

## Test Snapshots with Insta

When snapshot tests fail, you can review the diffs using:
```bash
cargo insta test --workspace --review
```
It will guide you interactively to accept or reject the snapshot regressions.

## Interpreting Reports
Coverage is generated in `target/coverage` for HTML reports or `lcov.info`. Focus on the critical unit tests and missing lines.
MSRV compilation uses Rust 1.91.0 explicitly in `.github/workflows/ci.yml`.

Ensure 100% of the newly written items (even internal implementations) are documented since `--document-private-items` is used.

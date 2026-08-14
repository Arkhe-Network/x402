#!/bin/bash
set -e

mkdir -p safe-core
cd safe-core

git init

echo "# SAFE-CORE OS — Monorepo" > README.md

cat << 'TOML' > Cargo.toml
[workspace]
members = [
    "crates/safe-core-core",
    "crates/safe-core-identity",
    "crates/safe-core-governance",
    "crates/safe-core-pea",
    "crates/safe-core-inference",
    "crates/safe-core-mcp-adapter",
]
resolver = "2"

[workspace.package]
version = "0.1.0"
edition = "2021"
authors = ["Arkhe OS Architects <safe-core@safe-core-os.org>"]
license = "MIT OR Apache-2.0"
repository = "https://github.com/safe-core-os/safe-core"
documentation = "https://docs.safe-core-os.org"
keywords = ["security", "governance", "ai", "ontology", "zk"]
categories = ["cryptography", "os", "security", "machine-learning"]
readme = "README.md"

[profile.dev]
opt-level = 0
debug = true
split-debuginfo = 'unpacked'

[profile.test]
opt-level = 1
debug = true

[profile.release]
opt-level = 3
lto = true
codegen-units = 1
strip = "symbols"
debug = false
panic = "abort"

[profile.bench]
opt-level = 3
lto = true
codegen-units = 1

[workspace.dependencies]
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
serde_yaml = "0.9"
toml = "0.8"
thiserror = "1.0"
anyhow = "1.0"
tokio = { version = "1", features = ["full"] }
async-trait = "0.1"
futures = "0.3"
blake3 = "1.5"
hmac = "0.12"
sha2 = "0.10"
rand = "0.8"
base64 = "0.22"
hex = "0.4"
ed25519-dalek = { version = "2.1", features = ["serde"] }
ml-dsa = { version = "0.2" }
x25519-dalek = { version = "2.0", features = ["serde"] }
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }
tracing-opentelemetry = "0.22"
opentelemetry = { version = "0.23", features = ["metrics"] }
chrono = { version = "0.4", features = ["serde"] }
uuid = { version = "1.10", features = ["v4", "serde"] }
url = "2.5"
regex = "1.10"
mockall = "0.13"
tempfile = "3.10"
criterion = { version = "0.5", features = ["html_reports"] }
clap = { version = "4.5", features = ["derive", "env"] }
indicatif = "0.17"
dialoguer = "0.11"
reqwest = { version = "0.12", features = ["json", "rustls-tls"] }
axum = { version = "0.7", features = ["json", "tracing"] }
tower = "0.4"
tower-http = { version = "0.5", features = ["trace", "cors"] }
sled = "0.34"
rocksdb = "0.22"
TOML

cat << 'TOML' > rust-toolchain.toml
[toolchain]
channel = "1.81.0"
components = ["rustfmt", "clippy", "llvm-tools-preview"]
targets = ["x86_64-unknown-linux-gnu", "aarch64-unknown-linux-gnu"]
profile = "minimal"
TOML

mkdir -p crates/safe-core-core/src crates/safe-core-core/benches
mkdir -p crates/safe-core-identity/src
mkdir -p crates/safe-core-governance/src
mkdir -p crates/safe-core-pea/src
mkdir -p crates/safe-core-inference/src
mkdir -p crates/safe-core-mcp-adapter/src
mkdir -p bin/safe-core-cli/src
mkdir -p tests/integration
mkdir -p scripts
mkdir -p docs
mkdir -p .cargo
mkdir -p .github/workflows

# crates/safe-core-core
cat << 'TOML' > crates/safe-core-core/Cargo.toml
[package]
name = "safe-core-core"
version.workspace = true
edition.workspace = true
authors.workspace = true
license.workspace = true
repository.workspace = true
readme.workspace = true
description = "Descrição sucinta do crate safe-core-core no SAFE-CORE OS"

[dependencies]
serde = { workspace = true }
serde_json = { workspace = true }
thiserror = { workspace = true }
tracing = { workspace = true }
chrono = { workspace = true }
blake3 = { workspace = true }

[dev-dependencies]
mockall = { workspace = true }
tempfile = { workspace = true }
criterion = { workspace = true }

[[bench]]
name = "benchmark"
harness = false
TOML

cat << 'RS' > crates/safe-core-core/src/lib.rs
pub fn blake3_hash(data: &[u8]) -> blake3::Hash {
    blake3::hash(data)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hash_roundtrip() {
        let hash = blake3_hash(b"test");
        let zero_hash = blake3::Hash::from_bytes([0; 32]);
        assert_ne!(hash, zero_hash);
        assert_eq!(hash.to_hex().len(), 64);
    }
}
RS

cat << 'RS' > crates/safe-core-core/benches/benchmark.rs
use criterion::{criterion_group, criterion_main, Criterion};
use safe_core_core::blake3_hash;

fn bench_hash(c: &mut Criterion) {
    let data = vec![0u8; 1024];
    c.bench_function("blake3 1KB", |b| b.iter(|| blake3_hash(&data)));
}

criterion_group!(benches, bench_hash);
criterion_main!(benches);
RS

# crates/safe-core-identity
cat << 'TOML' > crates/safe-core-identity/Cargo.toml
[package]
name = "safe-core-identity"
version.workspace = true
edition.workspace = true
authors.workspace = true
license.workspace = true
repository.workspace = true
readme.workspace = true
description = "Descrição sucinta do crate safe-core-identity no SAFE-CORE OS"

[dependencies]
safe-core-core = { path = "../safe-core-core" }
serde = { workspace = true }
serde_json = { workspace = true }
thiserror = { workspace = true }
tracing = { workspace = true }
chrono = { workspace = true }

[dev-dependencies]
mockall = { workspace = true }
tempfile = { workspace = true }
criterion = { workspace = true }
TOML

cat << 'RS' > crates/safe-core-identity/src/lib.rs
#[derive(Clone)]
pub struct ArkheDid {
    pub namespace: String,
    pub id: String,
}
impl ArkheDid {
    pub fn new(namespace: &str, id: &str) -> Self {
        Self { namespace: namespace.to_string(), id: id.to_string() }
    }
}
RS

# crates/safe-core-governance
cat << 'TOML' > crates/safe-core-governance/Cargo.toml
[package]
name = "safe-core-governance"
version.workspace = true
edition.workspace = true
authors.workspace = true
license.workspace = true
repository.workspace = true
readme.workspace = true
description = "Descrição sucinta do crate safe-core-governance no SAFE-CORE OS"

[dependencies]
safe-core-core = { path = "../safe-core-core" }
safe-core-identity = { path = "../safe-core-identity" }
serde = { workspace = true }
serde_json = { workspace = true }
thiserror = { workspace = true }
tracing = { workspace = true }
chrono = { workspace = true }

[dev-dependencies]
mockall = { workspace = true }
tempfile = { workspace = true }
criterion = { workspace = true }
TOML

cat << 'RS' > crates/safe-core-governance/src/lib.rs
use safe_core_identity::ArkheDid;
pub struct CapabilityToken;
impl CapabilityToken {
    pub fn issue(
        _issuer: ArkheDid,
        _subject: ArkheDid,
        _capabilities: Vec<String>,
        _ttl: std::time::Duration,
        _key: &[u8],
    ) -> Result<Self, String> {
        Ok(Self)
    }
}
RS

# crates/safe-core-pea
cat << 'TOML' > crates/safe-core-pea/Cargo.toml
[package]
name = "safe-core-pea"
version.workspace = true
edition.workspace = true
authors.workspace = true
license.workspace = true
repository.workspace = true
readme.workspace = true
description = "Descrição sucinta do crate safe-core-pea no SAFE-CORE OS"

[dependencies]
safe-core-core = { path = "../safe-core-core" }
safe-core-identity = { path = "../safe-core-identity" }
safe-core-governance = { path = "../safe-core-governance" }
serde = { workspace = true }
serde_json = { workspace = true }
thiserror = { workspace = true }
tracing = { workspace = true }
chrono = { workspace = true }

[dev-dependencies]
mockall = { workspace = true }
tempfile = { workspace = true }
criterion = { workspace = true }
TOML

cat << 'RS' > crates/safe-core-pea/src/lib.rs
use safe_core_identity::ArkheDid;

pub struct PolicyEngine;

pub enum TaskState {
    Running,
}

pub struct Intent;
impl Intent {
    pub fn new_root(_hash: &blake3::Hash, _did: ArkheDid, _action: &str, _data: &[u8]) -> Self {
        Self
    }
    pub fn advance_state(&mut self, _state: TaskState, _ctx: &()) -> Result<(), String> {
        Ok(())
    }
}
RS

# crates/safe-core-inference
cat << 'TOML' > crates/safe-core-inference/Cargo.toml
[package]
name = "safe-core-inference"
version.workspace = true
edition.workspace = true
authors.workspace = true
license.workspace = true
repository.workspace = true
readme.workspace = true
description = "Descrição sucinta do crate safe-core-inference no SAFE-CORE OS"

[dependencies]
safe-core-core = { path = "../safe-core-core" }
serde = { workspace = true }
serde_json = { workspace = true }
thiserror = { workspace = true }
tracing = { workspace = true }
chrono = { workspace = true }

[dev-dependencies]
mockall = { workspace = true }
tempfile = { workspace = true }
criterion = { workspace = true }
TOML

cat << 'RS' > crates/safe-core-inference/src/lib.rs
RS

# crates/safe-core-mcp-adapter
cat << 'TOML' > crates/safe-core-mcp-adapter/Cargo.toml
[package]
name = "safe-core-mcp-adapter"
version.workspace = true
edition.workspace = true
authors.workspace = true
license.workspace = true
repository.workspace = true
readme.workspace = true
description = "Descrição sucinta do crate safe-core-mcp-adapter no SAFE-CORE OS"

[dependencies]
safe-core-core = { path = "../safe-core-core" }
safe-core-identity = { path = "../safe-core-identity" }
safe-core-pea = { path = "../safe-core-pea" }
serde = { workspace = true }
serde_json = { workspace = true }
thiserror = { workspace = true }
tracing = { workspace = true }
chrono = { workspace = true }

[dev-dependencies]
mockall = { workspace = true }
tempfile = { workspace = true }
criterion = { workspace = true }
TOML

cat << 'RS' > crates/safe-core-mcp-adapter/src/lib.rs
RS

# .cargo/config.toml
cat << 'TOML' > .cargo/config.toml
[build]

[target.x86_64-unknown-linux-gnu]
linker = "clang"
rustflags = ["-C", "target-cpu=native"]

[target.aarch64-unknown-linux-gnu]
linker = "clang"

[alias]
co = "check --workspace"
t = "test --workspace"
b = "build --workspace"
r = "run --workspace"
fmt = "fmt --all"
clippy = "clippy --workspace -- -D warnings"
audit = "audit --workspace"
deny = "deny --workspace"
TOML

# .rustfmt.toml
cat << 'TOML' > .rustfmt.toml
edition = "2021"
max_width = 100
hard_tabs = false
tab_spaces = 4
use_small_heuristics = "Max"
reorder_modules = true
reorder_imports = true
reorder_impl_items = true
group_imports = "StdExternalCrate"
imports_granularity = "Crate"
match_block_trailing_comma = true
trailing_comma = "Vertical"
trailing_semicolon = true
blank_lines_upper_bound = 2
blank_lines_lower_bound = 0
format_code_in_doc_comments = true
use_field_init_shorthand = true
use_try_shorthand = true
normalize_comments = true
wrap_comments = true
TOML

# clippy.toml
cat << 'TOML' > clippy.toml
pedantic = true
allow-unwrap-in-tests = true
warn-on-all-doc-comments = true
check = ["security-fixes", "vulnerabilities"]
deny = [
    "duplicate-crates",
    "wildcard-dependencies",
    "multiple-versions"
]
TOML

# justfile
cat << 'MAKE' > justfile
CARGO := cargo

default:
	@just check
	@just test

check:
	{{CARGO}} check --workspace --all-features

lint:
	{{CARGO}} clippy --workspace --all-features -- -D warnings -D clippy::pedantic

test:
	{{CARGO}} test --workspace --all-features -- --nocapture

cov:
	cargo llvm-cov --workspace --lcov --output-path lcov.info

build:
	{{CARGO}} build --workspace --release

audit:
	{{CARGO}} audit

deny:
	{{CARGO}} deny check

fmt:
	{{CARGO}} fmt --all

graph:
	cargo depgraph --workspace --dot | dot -Tpng > deps.png

clean:
	{{CARGO}} clean

update:
	{{CARGO}} update -w

precommit:
	@just fmt
	@just lint
	@just test
	@just audit
	@just deny
MAKE

# .github/workflows/ci.yml
cat << 'YAML' > .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop, release/**]
  pull_request:
    branches: [main, develop]

env:
  CARGO_TERM_COLOR: always
  RUST_BACKTRACE: 1

jobs:
  build-and-test:
    name: Build & Test (Rust ${{ matrix.rust }})
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        rust: [1.81.0, stable, beta]
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Install Rust
        uses: dtolnay/rust-toolchain@master
        with:
          toolchain: ${{ matrix.rust }}
          components: rustfmt, clippy

      - name: Cache Dependencies
        uses: Swatinem/rust-cache@v2
        with:
          workspaces: |
            crates/* -> target
            bin/* -> target
          cache-all-crates: true

      - name: Check Formatting
        run: cargo fmt --all -- --check

      - name: Clippy (Lint)
        run: cargo clippy --workspace --all-features -- -D warnings -D clippy::pedantic

      - name: Build (Debug)
        run: cargo build --workspace --all-features

      - name: Run Unit & Integration Tests
        run: cargo test --workspace --all-features -- --nocapture

      - name: Run Doc Tests
        run: cargo test --workspace --all-features --doc

  security-audit:
    name: Security Audit
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install Rust
        uses: dtolnay/rust-toolchain@stable

      - name: Cache
        uses: Swatinem/rust-cache@v2

      - name: Install cargo-audit
        run: cargo install cargo-audit

      - name: Run cargo-audit
        run: cargo audit --workspace --ignore RUSTSEC-2023-0071

      - name: Install cargo-deny
        run: cargo install cargo-deny

      - name: Run cargo-deny
        run: cargo deny check --workspace

  build-release:
    name: Build Release
    runs-on: ubuntu-latest
    needs: [build-and-test, security-audit]
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install Rust
        uses: dtolnay/rust-toolchain@stable

      - name: Cache
        uses: Swatinem/rust-cache@v2

      - name: Build Release
        run: cargo build --workspace --release --all-features

      - name: Upload Artifacts (Opcional)
        uses: actions/upload-artifact@v4
        with:
          name: safe-core-binaries
          path: target/release/safe-core-*
YAML

# deny.toml
cat << 'TOML' > deny.toml
[graph]
targets = [
    { triple = "x86_64-unknown-linux-gnu" },
    { triple = "aarch64-unknown-linux-gnu" },
]
exclude = []
all-features = false
no-default-features = false

[advisories]
vulnerability = "deny"
unmaintained = "deny"
notice = "warn"
ignore = []

[licenses]
unlicensed = "deny"
allow = [
    "MIT",
    "Apache-2.0",
    "BSD-3-Clause",
    "ISC",
    "MPL-2.0",
    "Unicode-DFS-2016",
]
deny = []
copyleft = "warn"
allow-osi-fsf-free = "never"
default = "deny"

[bans]
multiple-versions = "warn"
wildcards = "deny"
highlight = "all"
workspace-default-features = "allow"
external-default-features = "allow"
TOML

# depgraph-rules.toml
cat << 'TOML' > depgraph-rules.toml
[rules]
safe-core-core = []
safe-core-identity = ["safe-core-core"]
safe-core-governance = ["safe-core-core", "safe-core-identity"]
safe-core-pea = ["safe-core-core", "safe-core-identity", "safe-core-governance"]
safe-core-inference = ["safe-core-core"]
safe-core-mcp-adapter = ["safe-core-core", "safe-core-identity", "safe-core-pea"]
safe-core-cli = ["*"]
TOML

# release.toml
cat << 'TOML' > release.toml
sign-commit = false
sign-tag = false
push-remote = "origin"
publish = false
workspace = true
dependent-version = "fix"
TOML

# .gitignore
cat << 'IGNORE' > .gitignore
/target/
**/*.rs.bk
*.pdb
*.dSYM

Cargo.lock

.idea/
.vscode/
*.iml

.DS_Store
Thumbs.db

*.lcov
*.profdata
*.profraw

/docs/book/
/docs/api/

/vendor/
IGNORE

# tests/integration/full_flow.rs
cat << 'RS' > tests/integration/full_flow.rs
use safe_core_core::blake3_hash;
use safe_core_identity::ArkheDid;
use safe_core_governance::CapabilityToken;
use safe_core_pea::{Intent, TaskState};

#[test]
fn full_end_to_end_flow() {
    // 1. DID
    let did = ArkheDid::new("safe-core", "agent-001");

    // 2. Token
    let key = b"supersecretkey";
    let _token = CapabilityToken::issue(
        did.clone(),
        did.clone(),
        vec!["tool:execute:risk_model".into()],
        std::time::Duration::from_secs(3600),
        key,
    ).unwrap();

    // 3. Intent
    let root_hash = blake3_hash(b"user_prompt");
    let mut intent = Intent::new_root(&root_hash, did.clone(), "risk_model", b"data");
    intent.advance_state(TaskState::Running, &Default::default()).unwrap();

    // 4. Policy Engine (Mock)
    // ... enforce

    // 5. Assertions
    // ...
}
RS

echo "Done generating safe-core directory!"

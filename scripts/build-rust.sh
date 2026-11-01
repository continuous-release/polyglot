#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${RELEASE_VERSION:-$(cat version.txt)}"
export RELEASE_VERSION="$VERSION"

node scripts/codegen.mjs --check
mkdir -p dist
cargo build --release --offline --manifest-path rust/Cargo.toml
cp rust/target/release/polyglot dist/polyglot
chmod +x dist/polyglot

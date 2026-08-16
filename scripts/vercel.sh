#!/usr/bin/env bash
set -euo pipefail

# Pin to the SDK that already builds this app locally.
FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.6}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export FLUTTER_ROOT="$ROOT/.flutter-sdk"
export PATH="$FLUTTER_ROOT/bin:$PATH"
export PUB_CACHE="${PUB_CACHE:-$ROOT/.pub-cache}"

if [[ ! -x "$FLUTTER_ROOT/bin/flutter" ]]; then
  rm -rf "$FLUTTER_ROOT"
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_ROOT"
fi

if [[ ! -f "$ROOT/lib/main.dart" ]]; then
  echo "lib/main.dart is missing. Check .vercelignore is not excluding lib/" >&2
  exit 1
fi

flutter config --no-analytics --enable-web >/dev/null
flutter pub get
flutter build web --release --no-tree-shake-icons --no-wasm-dry-run

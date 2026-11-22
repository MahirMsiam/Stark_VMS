#!/usr/bin/env bash
# Netlify build for Flutter Web (see ../netlify.toml). Output: build/web
set -euo pipefail

FLUTTER_DIR="$HOME/flutter"
# Pristine copy of the SDK's version file (kept outside bin/cache, which Flutter rewrites).
VERSION_DIST="$FLUTTER_DIR/bin/flutter.version.json.dist"
if [ ! -x "$FLUTTER_DIR/bin/flutter" ] || [ ! -f "$VERSION_DIST" ]; then
  # Download the official release archive (some build environments block `git clone`).
  FLUTTER_ARCHIVE="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION:?set FLUTTER_VERSION}-stable.tar.xz"
  rm -rf "$FLUTTER_DIR"
  mkdir -p "$(dirname "$FLUTTER_DIR")"
  curl -fsSL --retry 3 "$FLUTTER_ARCHIVE" | tar -xJ -C "$(dirname "$FLUTTER_DIR")"
  cp "$FLUTTER_DIR/bin/cache/flutter.version.json" "$VERSION_DIST"
fi
export FLUTTER_SUPPRESS_ANALYTICS=true

# The first run builds the flutter tool, which deletes bin/cache/flutter.version.json and tries
# to recompute the version with git. Where git is restricted that yields "0.0.0-unknown" and
# package resolution fails, so restore the version file shipped with the release afterwards.
"$FLUTTER_DIR/bin/flutter" --version >/dev/null 2>&1 || true
cp "$VERSION_DIST" "$FLUTTER_DIR/bin/cache/flutter.version.json"

if [ -z "${API_BASE_URL:-}" ]; then
  # Allowed so the site can be checked before the backend is live; the app then shows "Cannot reach the server".
  echo "WARNING: API_BASE_URL is not set - the app will call http://localhost:9001"
  API_BASE_URL="http://localhost:9001"
fi

"$FLUTTER_DIR/bin/flutter" --version
"$FLUTTER_DIR/bin/flutter" build web --release --dart-define=API_BASE_URL="$API_BASE_URL"

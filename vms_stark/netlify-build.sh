#!/usr/bin/env bash
# Netlify build for Flutter Web (see ../netlify.toml). Output: build/web
set -euo pipefail

FLUTTER_DIR="$HOME/flutter"
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "${FLUTTER_VERSION:?set FLUTTER_VERSION}" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

if [ -z "${API_BASE_URL:-}" ]; then
  # Allowed so the site can be checked before the backend is live; the app then shows "Cannot reach the server".
  echo "WARNING: API_BASE_URL is not set - the app will call http://localhost:9001"
  API_BASE_URL="http://localhost:9001"
fi

"$FLUTTER_DIR/bin/flutter" --version
"$FLUTTER_DIR/bin/flutter" build web --release --dart-define=API_BASE_URL="$API_BASE_URL"

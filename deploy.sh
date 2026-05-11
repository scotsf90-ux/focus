#!/usr/bin/env bash
# Deploy focus.html to GitHub Pages.
# Copies the source file as index.html, stamps the service worker cache version,
# and pushes. Run from anywhere.
set -euo pipefail

SRC=/Users/brain/claude/focus.html
WEB=/Users/brain/claude/focus-web
APP=$WEB/app
SW_TEMPLATE=$APP/service-worker.js

if [ ! -f "$SRC" ]; then
  echo "deploy: source not found at $SRC" >&2
  exit 1
fi

cp "$SRC" "$APP/index.html"

# Stamp service worker with build timestamp so the cache version bumps on every deploy
BUILD=$(date +%Y%m%d%H%M%S)
# Reset SW from a clean copy: replace any previous timestamped version with the placeholder, then with the new build.
# We use a tagged comment line as anchor to find/replace deterministically.
python3 - <<PY
import re, pathlib
p = pathlib.Path("$SW_TEMPLATE")
s = p.read_text()
s = re.sub(r"const CACHE_NAME = 'one-thing-v[^']+';", "const CACHE_NAME = 'one-thing-v$BUILD';", s, count=1)
p.write_text(s)
PY

cd "$WEB"
if git diff --quiet -- app/index.html app/service-worker.js; then
  echo "deploy: no changes to push"
  exit 0
fi

git add app/index.html app/service-worker.js
git commit -qm "deploy: build $BUILD"
git push -q

echo "deploy: pushed build $BUILD"
echo "deploy: live in ~30s at https://scotsf90-ux.github.io/focus/app/"

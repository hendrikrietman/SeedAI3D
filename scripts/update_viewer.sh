#!/usr/bin/env bash
# Copy the latest STL exports into viewer/models/ so the live viewer
# picks them up. Run from project root.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p viewer/models

# Mirror the STL tree into viewer/models, flattened (latest wins per name).
shopt -s nullglob
for f in stl/*/*.stl; do
  cp -v "$f" "viewer/models/$(basename "$f")"
done
shopt -u nullglob

echo "Done. Serve with:  python3 -m http.server -d viewer 8000"

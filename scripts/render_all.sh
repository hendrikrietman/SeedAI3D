#!/usr/bin/env bash
# Render every phase: STL exports + isometric/cross-section/front PNGs.
# Run from project root.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# OpenSCAD needs a GL context; xvfb-run handles headless servers.
RUN="xvfb-run -a"
command -v xvfb-run >/dev/null || RUN=""

phases=(
  "v4_1_disc:disc"
)

for entry in "${phases[@]}"; do
  src="${entry%%:*}"
  parts="${entry##*:}"

  scad_file="scad/${src}.scad"
  if [[ ! -f "$scad_file" ]]; then
    echo "[skip] $scad_file not found"
    continue
  fi

  phase="${src%%_*}_${src#*_}"   # v4_1, v4_2, ...
  phase="${phase%%_*}_${phase#*_}"
  phase="$(echo "$src" | sed -E 's/^(v[0-9]+_[0-9]+).*/\1/')"

  mkdir -p "stl/$phase" "renders/$phase"

  IFS=',' read -ra part_arr <<< "$parts"
  for part in "${part_arr[@]}"; do
    echo "[stl]      stl/$phase/${part}.stl"
    $RUN openscad -D 'EXPORT_MODE=true' \
      -o "stl/$phase/${part}.stl" "$scad_file" >/dev/null
  done

  echo "[render]   renders/$phase/${src}_iso.png"
  $RUN openscad --imgsize=1200,900 --camera=0,0,0,55,0,25,250 \
    -o "renders/$phase/${src}_iso.png" "$scad_file" >/dev/null

  echo "[render]   renders/$phase/${src}_cross.png"
  $RUN openscad --imgsize=1200,900 --camera=0,0,0,55,0,25,250 \
    -D 'ENABLE_CROSS_SECTION=true' \
    -o "renders/$phase/${src}_cross.png" "$scad_file" >/dev/null

  echo "[render]   renders/$phase/${src}_front.png"
  $RUN openscad --imgsize=1000,1000 --camera=0,0,0,90,0,0,250 \
    --projection=ortho \
    -o "renders/$phase/${src}_front.png" "$scad_file" >/dev/null
done

echo "Done."

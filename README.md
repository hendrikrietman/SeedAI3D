# PROTISEM V4 — Slanted Vacuum Seed Disc

Parametric CAD project for a 45° slanted vacuum seeding disc. Built in 10 sequential phases, each producing OpenSCAD source, STL exports, PNG cross-sections, and a working three.js HTML viewer.

See `CLAUDE.md` for full project memory and the per-phase plan.

## Quick start

```bash
# Render all current SCAD files to STL + PNG
bash scripts/render_all.sh

# Open the viewer
xdg-open viewer/index.html   # or: python -m http.server -d viewer 8000
```

## Layout

- `scad/` — OpenSCAD source, with shared `lib/parameters.scad` and `lib/helpers.scad`
- `stl/v4_<phase>/` — STL exports per phase
- `renders/v4_<phase>/` — PNG cross-sections + orthographic views per phase
- `viewer/` — three.js browser viewer (the live deliverable)
- `validation/` — Python checks: watertightness, clearances, seed paths
- `docs/` — BOM, build log, architectural decisions
- `scripts/` — render/export/update helpers

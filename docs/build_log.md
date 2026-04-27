# PROTISEM V4 — Build Log

## Phase 1 — Parametric disc + viewer bootstrap (2026-04-27)

- Disc compiles to a watertight STL: 5928 vertices, 11920 faces, volume ~40.5 cm³.
- Bounding box matches expectation for a 132 mm OD disc tilted 45° around world X (132 × 96.2 × 96.2 mm).
- Volume sanity check passed. Centroid at origin (within 0.001 mm).
- Resolved spec ambiguity: the pickup-zone coordinate `(0, 29.7, 29.7)` requires tilt around world X, not Y. See `docs/decisions.md` D1.
- Viewer scaffolded with three.js (vendored, 1.3 MB) + OrbitControls + STLLoader. Z-up convention propagated to camera.
- Smoke test: all seven viewer assets serve 200 via `python3 -m http.server -d viewer`.

## Phase 2 — Reservoir + viewer integration (2026-04-27)

- Reservoir compiles watertight: hull from 60×60 top to Ø16 outer/Ø12 inner outlet, 80 mm tall, 2 mm wall.
- Validation caught my hand-math error: I sized clearance to the inner rim (Ø12) but the collision happens at the outer rim (Ø16 with the 2 mm wall). Bumped `RESERVOIR_OUTLET_CLEARANCE` 14 → 17 mm. Decision D4.
- Min disc-reservoir clearance now 6.5 mm (≥5 mm required), measured by trimesh proximity sampling 4000 surface points.
- Phase-2 cross-section uses the X-plane (cuts +X), not the Y-plane (Phase-1's choice). The reservoir lives entirely in +Y; cutting +Y would erase it.
- Viewer now loads `disc.stl` + `reservoir.stl`, renders the reservoir translucent grey, drops Ø6 yellow seed spheres from the outlet under (visualisation-scaled) gravity, lands them on the disc top plane (`z = y + 2.828`) within the disc body annulus (R 25–60), and removes them 1.5 s after landing.
- New "Seed feed" slider (0–10/s). All eight viewer assets still serve 200.

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

## Phase 2 fix — pickup/release positions corrected (2026-04-27)

- The V4 drawing's "Vooraanzicht schijf" panel shows pickup AND release both near the TOP of the disc, symmetric around the Y axis. The previous Phase-2 release marker at (0, −29.7, −29.7) was the disc's lowest point — wrong. Decision D5.
- Introduced `PICKUP_THETA_DEG = 110` and `RELEASE_THETA_DEG = 70` in `parameters.scad`, deriving world coordinates from `(R·cosθ, R·sinθ·cos45°, R·sinθ·sin45°)`.
- New marker positions:
  - PICKUP  (red)    = (−14.365, 27.907, 27.907)  θ=110°
  - RELEASE (orange) = (+14.365, 27.907, 27.907)  θ=70°
  - Both at world-Z = 27.9. Seed travels CCW the long way (~320°): pickup → bottom → release.
- Reservoir outlet shifted: now directly above PICKUP at (−14.365, 27.907, 35.000), 7.1 mm vertical above the pickup mid-plane. `RESERVOIR_OUTLET_CLEARANCE` 17 → 7.1.
- Rotation direction confirmed CCW (positive ω around DISC_AXIS): velocity at release is (0, +y, +z) — front-face-rises-on-the-release-side, matches Hendrik's "schijf draait aan voorzijde omhoog".
- **Validation regression:** with the smaller clearance, the +Y outer rim of the Ø16 outlet wall clips the disc at min = 0.10 mm @ (−19.7, 32.3, 35.0). All other checks pass. Three options to recover ≥5 mm: (a) raise outlet to z ≈ 45.8 (clearance back to ~17.9 mm), (b) shrink outlet to Ø6 inner / no flange and re-check, (c) tilt the outlet plane parallel to the disc. Pending Hendrik's call — see D5.

### Phase 3 physics note (deflector + funnel is mandatory, not optional)

At release (+14.4, 27.9, 27.9) and 5 RPM, the pickup hole's tangential speed is ω·R = (5·2π/60)·42 ≈ 22 mm/s. If the seed simply detaches and free-falls under gravity, it crosses z=0 at world (~12, 28, 0) — well outside the central hole (R=25 around origin). Conclusion: **a seed released without guidance misses the central hole** and lands on the back face of the disc. Phase 3 must therefore include a deflector ramp from the release zone toward the central hole; the trickle-funnel cannot be ornamental.

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

## Phase 2 V5 — architecture switch: top reservoir → bottom seed-pool (2026-04-27)

> Phase 2 V5: architectuur omschakeling van top-reservoir (V4) naar bottom
> seed-pool (V5) op verzoek van Hendrik. Reden: vacuum-pickup uit zaad-pool
> is conceptueel beter voor singulatie-precisie (Earthway/MaterMacc/Monosem
> patroon) en geeft betere kinetische voorwaarden bij pickup (zaad op
> snelheid 0). Wel architectureel ander dan V4-tekening — dit is V5 niet V4.

What changed:

- Pickup θ moved to **270°** (disc bottom, world (0, -29.7, -29.7)). Release θ moved to **90°** (disc top, world (0, +29.7, +29.7)). Both on X=0 plane.
- Travel arc is now **180°** along the disc rim, decreasing θ (Option 1 — front face rises into release).
- `scad/v4_2_reservoir.scad` deleted; replaced by `scad/v5_2_seed_pool.scad`.
- Pool: 60 × 40 × 20 mm open bowl, centred at (0, -30, -35). V-trough bottom (6 mm strip) so seeds gather along the disc-rim dip line.
- Disc-envelope subtraction carves slots through the X=±30 side walls so the disc can dip in. Floor and front/back walls stay sealed.
- `parameters.scad`, `validation/geometry_check.py`, viewer (markers, animation, UI) all rewritten.

Geometric findings worth flagging:

1. **Disc TEETH dip below pool floor.** Tooth tips at α=270°, z_l=-2 sit at world z=-48.09. Pool floor at z=-45 → 3.09 mm interference. The SCAD model clips the disc envelope to z ≥ floor+1 so the *digital* floor stays sealed, but a real disc spinning at 5 RPM would saw into a real floor at z=-45. Two clean fixes available:
   - Lower pool floor to z=-50 (5 mm clearance below tooth tips). Pool depth becomes 25 mm.
   - Remove gear teeth from the disc until Phase 6 (gear drive). Phase 1 disc would become OD=120 (no teeth).
   Validation flags this as `disc_above_floor: gap=-2.22 mm` — left failing on purpose so the choice is in front of Hendrik.

2. **Seed-pool side-wall slots leak.** Real Monosem/MaterMacc seeders use brushes/wipers around the disc to seal these slots so seeds don't escape. The SCAD model cuts clean slots; sealing is a Phase-3 (or later) concern.

3. **Released seed misses central hole.** At release (0, 29.7, 29.7), tangential velocity is ~22 mm/s in +X (5 RPM). Free-fall trajectory enters disc body at (0.5, 29.7, 26.9), r_local=40 (between central hole at R=25 and outer rim at R=60). Lands on disc back face. Same conclusion as before: Phase 3 deflector is non-negotiable.

Acceptance status:
- All Phase-1 disc checks: PASS.
- Pool checks (file/watertight/bbox/z_bounds/y_centre): PASS.
- `disc_above_floor`: FAIL by 2.22 mm — pending Hendrik's call (lower floor or strip teeth).

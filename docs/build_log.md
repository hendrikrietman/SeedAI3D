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

## Phase 3 V5 — afstrijker + geleider + lifecycle animation (2026-04-27)

Two changes bundled because they only make sense together:

1. **Afstrijker + geleider + drop-tube** added (the components originally
   planned for Phase 3). New SCAD file `scad/v5_3_barriere_geleider.scad`
   wires all three:

   - **Afstrijker** — flat blade (18×2×8 mm) tangent to disc rim at
     θ=250° (20° past pickup, per Phase-3 spec). Sits on the disc-front
     face, 7 mm offset along DISC_FRONT_NORMAL. World centroid
     (-14.36, -22.96, -32.86) — geometrically inside the seed-pool
     volume; the rim has not yet emerged from the pool at θ=250°. Spec
     wording is preserved; pool-emergence point is θ≈237.5°. Function:
     5% probability of knocking off attached seeds (singulation), in
     the viewer's animation only — physical SCAD is just a blade.
   - **Geleider** — lofted hull from rect catch-mouth (40×20 at z=20,
     y_center=30) to circular throat (Ø30 at z=-6, y=0). Walls 2 mm.
     Throat lowered from spec'd z=5 to z=-6 because a straight loft from
     z=20 to z=5 crosses the disc-body slab (|z-y| ≤ 2.83 mm) at
     intermediate z; lowering throat below the slab eliminates the
     interference at the path's centre. Disc-envelope-with-3 mm-clearance
     is also subtracted from the geleider (analogous to the seed-pool
     side-wall slots) to carve clean rotation room — slot leaks; sealing
     brushes deferred to a later phase.
   - **Drop-tube** — straight pipe Ø30 OD / Ø24 ID from geleider throat
     (z=-6) down to z=-52 (below pool floor). Fits Ø50 central hole with
     10 mm radial slop on each side.

2. **Seed-flow animation overhaul.** Phase-2 viewer steady-state showed
   "Pool 0 / On-disc 0 / Released 80" — pool drained in ~24 s and stayed
   empty. Two bugs fixed:

   - **Visibility.** Camera lives at world -Y. Physical disc-front face
     normal is +Y (seeds press against it from the pool). Attached seeds
     placed on the physical front face were on the FAR side of the disc
     and hidden behind it. Viewer now uses `DISC_FRONT_VIS = +DISC_NORMAL`
     for visualisation only — seeds appear on the camera-side face. The
     SCAD afstrijker stays on the real (physical) front face.
   - **Pool starvation.** Pool now refills automatically when it drops
     below 12 seeds, back up to 50. Animation runs indefinitely.

   Full lifecycle state machine:

   `pool → attached → falling → gliding → exiting → landed`

   plus the afstrijker's `attached → pool` knock-back transition. Per-state
   counters on the HUD: pool / on-disc / in-geleider / in-drop-tube
   (current totals) and sown / skipped / missed (cumulative). Fall →
   geleider catch is detected by AABB overlap with the catch-mouth bounds
   (x ∈ ±20, y ∈ [20, 40], z ∈ [16, 22]). Glide is a smoothstep lerp from
   catch position to throat (0.4 s vis time). Exit is a linear lerp down
   the drop-tube (0.35 s).

Acceptance status (geometry_check.py):
- Phase-1 disc, Phase-2 pool: PASS.
- Phase-3 afstrijker (file/watertight/centroid-at-θ=250-on-front-face): PASS.
- Phase-3 geleider (file/watertight/z-bounds/x-extent/disc-clearance≥3 mm): PASS.
- Phase-3 drop-tube (file/watertight/z-bounds/fits-central-hole): PASS.
- `disc_above_floor`: still FAIL by ~2.2 mm — open D6 question, unchanged.

All eleven viewer assets serve 200 (disc + pool + afstrijker + geleider +
drop_tube STLs, plus index.html / viewer.js / styles.css / three.module.js
+ OrbitControls + STLLoader).

## Phase 3 V5 visual fixes — seed offset, raised pool, release pusher (2026-04-27)

Three small visual issues from Hendrik's first-pass review of the Phase-3
animation, fixed in one update:

1. **Seed offset 5 mm in disc-front-normal direction.** Attached red seeds
   were rendering with their centres on the disc mid-plane, which made them
   look embedded in the disc face. Bumped `SEED_OFFSET` from `SEED_RADIUS`
   (3 mm) to a fixed 5 mm so the sphere's near pole lightly touches the disc
   surface and most of the sphere is visible in front. Direction unchanged
   (`DISC_FRONT_VIS = (0, -sin45°, +cos45°)`, the camera-facing face).

2. **Seed-pool raised 8 mm.** Pool floor `−45 → −37`, walls top `−25 → −17`,
   fill line `−32 → −24`. The pool seed pile (top now at z≈−24) sits well
   above the disc tooth-rand sweep at θ=270° (z≈−46.7), so seeds no longer
   visually overlap with the teeth. Disc-rim mid-plane (z=−29.7) still dips
   ~12.7 mm into the open pool, so vacuum pickup at θ=270° still passes
   through seed mass.

   *Side effect on D6 floor-clearance:* the disc tooth tip at α=270° (world
   z=−47.82) now sits 10.82 mm BELOW the raised pool floor at z=−37 (was
   2.22 mm). The validator still reports `disc_above_floor: gap=−10.82 mm`
   — the SCAD model still digitally seals the floor by clipping the disc
   envelope subtraction, but the physical interference is now larger. D6's
   open question (lower the floor below tooth tips OR strip teeth until
   Phase 6) is more pressing; Hendrik's call still pending.

3. **Second afstrijker at θ=95°** (5° before the natural release at θ=90°).
   New SCAD module `afstrijker2()` — same construction as the first blade,
   but shorter (12 mm) and lower (6 mm). Centroid (−3.66, +33.83, +25.34)
   matches expected within 0.00 mm. Function in the viewer: ~10% probability
   per pass that an attached seed passing under it gets "pushed" off the
   disc straight into the geleider catch-mouth (skipping the falling state),
   visualising the redundancy against imperfect vacuum cutoff. New
   `savedCount` counter tracks pushed-and-saved seeds. Both afstrijkers are
   now individually toggleable in the controls panel.

Acceptance status (geometry_check.py):
- All Phase-1 / Phase-2 / Phase-3 component checks PASS, including the new
  `centroid_at_θ=95_on_front_face` check on afstrijker2.
- `disc_above_floor`: now FAIL by 10.82 mm (was 2.22 mm before raised pool).
  Pre-existing D6 issue, unchanged in spirit, magnified by visual fix.

All twelve viewer assets serve 200 (now adds afstrijker2.stl).

## Phase 3 V5 fix — FRONT_NORMAL derived from pool reference (2026-04-27)

The previous attempt placed attached seeds along `DISC_FRONT_VIS = +DISC_NORMAL
= (0, -sin45°, +cos45°)`, justified at the time as a "visibility hack" because
seeds on the physical front face would be hidden behind the disc from the
default camera. That sign was wrong: the seeds appeared embedded in the disc
plane in side-view because the offset direction was the back-face normal.

**Root-cause fix.** Use the pool as ground truth. By construction, pool
seeds are below the disc on the front side — that's the whole point of
vacuum pickup. Define

```
disc_plane_eq(x, y, z) = -sin45°·y + cos45°·z
```

A pool seed at, e.g., (0, -29.7, -33) gives `disc_plane_eq = -2.33 < 0` →
front side. So FRONT_NORMAL is the unit vector pointing in the direction
of decreasing disc_plane_eq:

```
FRONT_NORMAL = -∇(disc_plane_eq) = (0, +sin45°, -cos45°) ≈ (0, +0.707, -0.707)
```

This is the SAME direction the SCAD afstrijkers were already mounted at —
validation showed afstrijker centroid at θ=250° offset from rim by
`h·(0, +sin45°, -cos45°)`. So the SCAD was right; only the viewer had the
wrong sign. Fixed: `FRONT_NORMAL` replaces `DISC_FRONT_VIS`, attached seeds
offset 5 mm in this direction.

Verification baked into the viewer:
- At startup, the topmost pool seed's `disc_plane_eq` is logged. Expected
  to be ≤ 0 (front side).
- At first pickup, the hole's and the attached seed's `disc_plane_eq` are
  logged. Expected: `seed < hole` (seed sits on front side, hole on plane).
- Sanity-check independently confirmed for θ ∈ {270°, 250°, 95°, 90°}:
  hole_eq = 0, seed_eq = −5 in all four cases.

After this fix, attached seeds at θ=270° land at world (0, -26.16, -33.23) —
inside the pool volume, sitting on the disc front face. At θ=90° they land
at (0, +33.23, +26.16) — directly above the geleider catch-mouth (mouth
y∈[20,40], z=20 to z=22), so the seed enters the catch zone naturally as
gravity pulls it down.

## Phase 4 V5 — Vacuum chamber + 4 mm holes + corrected seed mechanics (2026-04-27)

This phase is the LAST visual fix before STL export and PLA proof-of-concept
print. Three bundled changes:

**Change 1 — Pickup hole Ø 2.5 mm → Ø 4.0 mm.**
Soybean Ø ≈ 6 mm. The original 2.5 mm was a design holdover; the seed
only needs to seat against the disc-front around the hole, not pass
through. Increased to 4.0 mm: still strictly less than the seed diameter
(seed cannot escape forward through the hole), but with 60% more open
suction area per hole — better grip, more forgiving alignment. Updated
parameter `PICKUP_HOLE_DIA = 4.0` with comment locking the rationale.
Re-exported `disc.stl` (5928 vertices, volume 39 308 mm³).

**Change 2 — Attached-seed offset = SEED_RADIUS, not 5 mm.**
The previous viewer offset was 5 mm — picked when the conceptual model
was "seed centroid sits 5 mm in front of the hole". The physical model
is different: the seed-bottom *touches* the disc-front face, centred on
the hole. So the centre-to-disc offset is exactly SEED_RADIUS = 3 mm.
Changed `SEED_OFFSET = 5` (removed) → `FRONT_NORMAL.* * SEED_RADIUS` in
the three coordinate updates. Visually: attached seed now sits flush
against the disc; cross-section confirms seed-bottom on disc plane.

**Change 3 — Vacuum chamber on disc-back face.**
The missing structural element. Without a chamber, the vacuum has no
enclosure; pickup-holes inside the chamber sector experience suction,
holes outside it do not. The chamber is an annular sector hollow shell:

- Radii: `R_in = 30`, `R_out = 50` (pickup-hole circle R=42 sits inside).
- Depth: 8 mm along disc-back-normal (pre-tilt +Z).
- Sector: disc-local θ ∈ [90°, 270°] going through θ=180°, i.e. the
  half-plane `x_local ≤ 0`.
- Wall thickness: 2 mm; back plate, two end-walls, inner & outer
  cylinder walls. Open against the disc-back face (the disc itself
  forms the front cover — implicit O-ring grooves at R=30 and R=50).
- Hose nipple Ø 12 × 30 mm at the centre of the arc (θ=180°, R=40),
  pointing along disc-back-normal. After the SCAD `rotate([45,0,0])`,
  the nipple's far end ends up around world (-40, -25.5, +25.5).

New SCAD file: `scad/v5_4_vacuum_chamber.scad`. New parameters block in
`parameters.scad`: `VAC_CHAMBER_R_IN/R_OUT/DEPTH/WALL`,
`VAC_NIPPLE_DIA/LENGTH`, `VAC_SECTOR_START_DEG/END_DEG`. Exported
`stl/v5_4/vacuum_chamber.stl`: 392 vertices, 780 faces, watertight.

**Validation.** New `check_vacuum_chamber()` in `geometry_check.py` —
all PASS:
- `file_exists`: 392 vertices, 780 faces.
- `watertight`: True.
- `sector_x_range`: x ∈ [−50, 0] (chamber occupies the back-arc only).
- `centroid_on_back_side`: (−26.67, −6.67, +6.67) — x<<0 confirms sector,
  y<0, z>0 confirm the chamber is behind the tilted disc.

**Viewer integration.**
- New `vacuumChamberMat` material: blue-grey, opacity 0.30 — semi-
  transparent so attached seeds remain visible behind the chamber walls.
- Loaded via STLLoader; UI toggle "Vacuum-kamer (transparant)" controls
  visibility. Cross-section clipping plane added to the chamber material.
- Per-hole vacuum-glow markers: 40 small additive-blended blue spheres,
  one per pickup hole. Each frame, marker visibility = (vacuum > 5 AND
  hole's world x ≤ 0). Visualises which holes are *currently* in the
  chamber sector and active. UI toggle "Vacuum-glow" controls the glow.
- Vacuum-off behaviour: with the slider at 0%, every attached seed is
  immediately detached to falling at zero tangential velocity (drops
  straight down, almost certainly missed). At 5%-100% pickup proceeds
  normally — the binary cutoff at 5% is arbitrary, just there to model
  "vacuum on / vacuum off" without a smooth retention curve.

**Re-validation.** All component checks PASS, including the new chamber
checks. The pre-existing `disc_above_floor` D6 regression is unchanged
in nature (now reads −10.45 mm with the 4 mm-hole disc; was −10.82 mm
before). Decision still pending: lower pool floor to z = −50 OR strip
teeth until Phase 6.

**Tag:** v5.4. Phase 4 closes the V5 functional viewer. Next:
print preparation — production STL export, PLA proof-of-concept print
(disc + pool + afstrijkers + geleider + drop-tube + vacuum chamber).

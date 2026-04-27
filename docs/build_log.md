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

## V5 anchor-based verification (2026-04-27)

Replaced abstract coordinate reasoning with anchor-based positioning. The
afstrijkers physically must be on the seed-side of the disc — that's their
job. They are therefore the visual ground truth. Once afstrijker positions
are derived from FRONT_NORMAL and confirmed visible on the pool side, all
other front-side components (attached seeds, geleider mouth) are positioned
along the same FRONT_NORMAL; the back-side component (vacuum chamber +
hose nipple) is positioned along -FRONT_NORMAL.

**FRONT_NORMAL (unchanged)**: `(0, +sin45°, -cos45°) ≈ (0, +0.707, -0.707)`.

**Anchor logging in viewer.js.** Added `logAnchorReport()` that runs at
startup and prints expected centroids for: afstrijker1 (θ=250°),
afstrijker2 (θ=95°), seed at pickup (θ=270°), geleider mouth, and chamber.
For each anchor it logs the same-Y-sign test (does it match the pool /
release reference?) plus the sign of disc_plane_eq (negative = front,
positive = back). On STL load, every loaded mesh's centroid is compared
to the computed anchor — afstrijker1 / afstrijker2 / chamber via
Euclidean distance with tolerance, geleider via sign-of-eq alone (its
curved hull spreads its centroid).

**Three-view rendered confirmation** (renders/v5_4_anchor/):

- `iso.png` — familiar iso-view; chamber annular ring + hose nipple
  visible behind disc, pool box at bottom in front of disc, drop-tube
  through centre, red/orange θ markers at rim bottom and top.
- `side_x.png` — camera at +X; disc appears as tilted blue stripe
  diagonal across frame; pool box at lower-left (front-side of disc
  plane line), chamber back-block + nipple cylinder at upper-right
  (back-side of disc plane line). Disc plane visibly separates the
  two halves.
- `front.png` — camera at -Y; disc seen full-face with 60 teeth.
  Pool box at bottom in front of the disc. Chamber barely visible as
  a translucent ring silhouette behind the upper half of the disc;
  hose nipple peeks out top-left. Matches the spec ("chamber should
  be HIDDEN behind disc or barely visible as silhouette").

**Acceptance criteria — all met**:

- [x] Both afstrijkers on the pool-side of disc (afstrijker1 at θ=250°
  with y=-22.96 same-sign as pool y_center=-30; afstrijker2 at θ=95°
  with y=33.83 same-sign as release y=+29.7)
- [x] Attached seeds on pool-side (seed at pickup: y=-27.6, z=-31.8;
  inside pool footprint, on front side of disc plane)
- [x] Geleider catch-mouth on pool-side (mouth y_center=+30, z=20;
  disc_plane_eq=-7.07 < 0, front side)
- [x] Vacuum chamber on opposite side (chamber centroid (-26.67, -6.67,
  +6.67); disc_plane_eq=+9.43 > 0, back side)
- [x] Side-view + front-view PNGs visually confirm the separation
- [x] Console log emits FRONT_NORMAL value and per-anchor verification
  on every viewer load

No SCAD changes; all geometry already at correct positions from prior
phases. This is a documentation/verification step that closes the
"which-side-is-front" thread for good. Skipping rubber-seal work as
per spec — that's a separate prompt.

## V5 FLIP — seeds and chamber side-swap (2026-04-27)

Hendrik observed in the viewer: "Seeds should be on the OTHER side of the
plate, and on that same side all the seeds in the reservoir. The vacuum
chamber should be placed BEHIND instead!" — i.e. the camera-visible side
(operator side) must show pool + attached seeds + afstrijkers, with the
vacuum chamber + nipple hidden behind the disc.

The previous anchor verification correctly proved the disc plane separated
the two halves, but the assignment of which-side-is-which had the chamber
on the operator-visible side. This entry inverts that.

**Sign flip**:

- `FRONT_NORMAL` was `(0, +sin45°, −cos45°) ≈ (0, +0.707, −0.707)`.
- Now `FRONT_NORMAL = (0, −sin45°, +cos45°) ≈ (0, −0.707, +0.707)` —
  points toward the default camera at (−Y, +Z).

**SCAD changes**:

- `scad/v5_4_vacuum_chamber.scad` — `vacuum_chamber()` now wraps
  `vacuum_chamber_pretilt()` in `mirror([0,0,1])` before the disc-tilt
  rotate. Chamber moves from +Z pre-tilt to −Z pre-tilt; after the
  rotate it sits behind the disc (operator's far side).
- `scad/v5_3_barriere_geleider.scad` — `afstrijker()` and `afstrijker2()`
  had their `mirror([0,0,1])` removed. Blades stay on the +Z pre-tilt
  face; after the rotate they end up on the operator-visible side
  (same side as the new attached seeds, where they physically must be
  to function as singulators).

**STL re-exports** (centroids):

- `vacuum_chamber.stl`: was (−26.67, −6.67, +6.67) → now
  (−26.67, +6.67, −6.67); disc_plane_eq = −9.43 (chamber side).
- `afstrijker.stl`: was (−14.36, −22.96, −32.86) → now
  (−14.36, −32.86, −22.96); seed side (eq ≈ +7.07).
- `afstrijker2.stl`: was (−3.66, +33.83, +25.34) → now
  (−3.66, +25.34, +33.83); seed side (eq ≈ +6.06).

**Validation** (`validation/geometry_check.py`): chamber centroid check
relabelled `centroid_on_chamber_side` (asserts cy>0, cz<0, eq<0);
afstrijker centroid checks switched to the flipped FRONT_NORMAL and
relabelled `_on_seed_side`. All Phase-3/4 checks PASS post-flip.
Pre-existing D6 `disc_above_floor` regression unchanged.

**Viewer changes** (`viewer/viewer.js`):

- `FRONT_NORMAL` flipped to `(0, −SIN_T, +COS_T)`; comment block
  rewritten for the operator-visible-side rationale.
- `ANCHOR.chamber` expected centroid updated to (−26.67, +6.67, −6.67).
- `placePoolSeed()` rewritten to constrain every reservoir sphere to
  the eq>0 (seed-side) half-space: pick layer-z first, clamp y so
  that `y < z − 1.5`. Result is a wedge of seeds piling against the
  far-y end of the pool, all on the camera-visible side of the disc
  plane.

**Three-view rendered confirmation** (renders/v5_4_anchor/, overwritten):

- `iso.png` — chamber + nipple barely visible behind upper disc edge;
  afstrijkers + pool + drop-tube visible in front of disc.
- `side_x.png` — disc as tilted blue stripe; pool box at lower-left
  (front side), chamber back-block + nipple cylinder at upper-right
  (back side). Plane separates the two halves with the new assignment.
- `front.png` — face-on view: afstrijker 2 visible at top of disc, pool
  transparent in front, chamber/nipple completely hidden behind disc.
  Textbook "pump from behind, seed from front" configuration.

**Tag**: v5.4.2.

---

## V5 polish — vacuum-respecting release glide + front-face tube ports (2026-04-27)

Three issues addressed in one pass:

**1. Seed-fall through disc at θ=90° release.** Old behaviour at top
release fell vertically from rim, visually clipping the disc plate
slab on the way down. With vacuum still on, seeds should ride the
disc face inboard until they clear the central hole, then drop. Added
a 2-stage glide in `viewer/viewer.js` (`glideToThroat`):

- Stage 1 (0.45 s): rim point (0, +29.7, +29.7) → disc-axis point
  (0, +2.12, +2.12), a slide along the disc FRONT face at constant
  disc-local-Z = +3 mm. Provably non-clipping: |Z|=3 > slab half-
  thickness 2, and once R<25 the disc has a central hole anyway.
- Stage 2 (0.30 s): central-axis point → geleider throat top
  (0, 0, throatZ+1). Linear drop down the central hole.

`pushToGliding()` now delegates to `glideToThroat()`. `updateGliding()`
handles `stage` field for two-stage entries (smoothstep on stage 1,
linear on stage 2). At-top release in animate loop replaces the
previous `detachToFalling` call with `glideToThroat(state.seed)`.

**2. Darker, less transparent shell materials** (`viewer/viewer.js`):

| Material         | Old colour / opacity        | New colour / opacity      |
|------------------|-----------------------------|---------------------------|
| `poolMat`        | grey-blue 0x6a7886 / 0.45   | charcoal 0x3c4248 / 0.62  |
| `afstrijkerMat`  | warm grey 0x9ea4ad / 0.85   | dark grey 0x484c54 / 0.92 |
| `geleiderMat`    | lighter grey 0x4d5560/0.55  | near-black 0x2c3036/0.72  |
| `dropTubeMat`    | lighter grey 0x4d5560/0.65  | near-black 0x2c3036/0.82  |
| `vacuumChamberMat`| blue-grey 0x4d6075 / 0.45  | deep slate 0x232b34/0.62  |

Specular bumped to 0x111114 / 0x111118 across the board for a slight
sheen on the darker tone.

**3. Feeder + vacuum-cleanup tube ports on operator-facing front face.**
New parameters in `scad/lib/parameters.scad`:

- Feeder tube: OD 16, ID 12, length 50, 60° elevation, anchored at
  (x=+15, y=front, z=−22).
- Vac-cleanup tube: OD 32, ID 28, length 50, 45° elevation, anchored
  at (x=−15, y=front, z=−22).

Both modelled as cylinders along +Z then `rotate([90 - elev_deg, 0, 0])`
to tilt outward (-Y, +Z). Outer overlaps the wall; bore extends 5 mm
further inboard to fully pierce. New modules in `scad/v5_2_seed_pool.scad`:
`front_tube_outer/bore`, `feeder_tube_outer/bore`, `vac_clean_tube_outer/bore`.
`seed_pool()` unions tube outers, subtracts tube bores alongside the
existing pool cavity and disc envelope.

**STL re-export** (`stl/v5_3/seed_pool.stl`): 32v/60f → 865v/1742f;
copied to `viewer/models/seed_pool.stl`.

**Validation** (`validation/geometry_check.py`): Phase-2 pool checks
rewritten for tube extents:

- `x_extent_with_tubes`: 60.0 ±2.5 (vac tube nudges by ~1 mm)
- `z_floor`: exact at z = −37 (floor unaffected by tubes)
- `z_top_or_higher`: z_max ≥ −17 (tubes extend higher in +Z)
- `y_back_face`: exact at y = −10 (back wall unaffected)
- `y_front_or_further`: y_min ≤ −50 (tubes extend in −Y)

All five PASS at actual values (61.00, −37.00, 25.30, −10.00, −96.67).
Pre-existing `disc_above_floor` failure unchanged (teeth at z=−47.76
clipped by `disc_envelope_above_floor` half-space cut at z = floor+1).

**Tag**: v5.4.3.

---

## V5.5.0 — wider feeder + vac tube relocated to top, near-vertical (2026-04-27)

Stage A of Hendrik's Phase-5 spec. Stage B (half-circle recovery bowl
that wraps the disc 180° front-side) is deferred to v5.5.1 pending
review of this stage.

**Feeder tube — widened.** OD 16→18, ID 12→14. Bigger bore reduces
bridging risk for soybeans (Ø~6 mm). Same anchor (15, −50, −22),
same 60° elevation. Outer extent unchanged in X (still within +30
wall), nudges further in −Y/−Z (heavier tilt-cone footprint).

**Vac-cleanup tube — relocated.** Was: front-mount at (−15, −50, −22),
45° elevation, OD32/ID28. Hendrik's revised intent: vacuum mouth
"basically nearly inside the hopper" so suction lifts pool seeds
straight up, not pulling them sideways through a wall. Now:

- Anchor: mouth INSIDE pool at (0, −42, −30) — 7 mm above floor, on
  seed-side of disc plane (eq=+8.5 mm clearance from disc body slab).
- Elevation: 80° from horizontal (10° off vertical).
- Tilt direction: −Y from vertical → upper end is on operator side,
  hose attach reachable without fouling disc upper-half.
- OD/ID: 26/22 (matches standard Ø22 shop-vac hose + 2 mm wall).
- Length: 25 mm inside pool (mouth → top wall pierce) + 60 mm outside
  (hose attach span).

New `vac_clean_tube_outer/bore` modules in `scad/v5_2_seed_pool.scad`
no longer use `front_tube_*` helpers — they place the cylinder at
the mouth and rotate the whole thing by `90 - elev` (= 10°) about X.

**STL re-export** (`stl/v5_2/seed_pool.stl`): 865v/1742f → 899v/1810f.
Bounds: x[−30, +30] (was [−31, +30]); y[−82.79, −10] (was [−96.67,
−10]); z[−37, +55.97] (was [−37, +25.30]). Watertight. Copied to
`viewer/models/`.

**Validation** (`validation/geometry_check.py`): tightened
`x_extent_with_tubes` tolerance from ±2.5 to ±1.0 (vac tube no
longer pushes x_min past −30). Other four pool checks unchanged.
All five PASS at (60.00, −37.00, 55.97, −10.00, −82.79).
Pre-existing `disc_above_floor` failure unchanged.

**Cache-bust** in `viewer/viewer.js` (`?v=Date.now()` per page load)
ensures STL refetch on every page open — diagnostic console.log
prints loaded bounds for verification against the validation output.

**Tag**: v5.5.0.

---

## V5.5.1 — V-cone in both X & Y, floor lowered to clear disc teeth (2026-04-27)

Stage B-prep of Hendrik's Phase-5 spec — narrows the bowl into a true
V-cone in both dimensions and resolves the long-standing
`disc_above_floor` validation failure. The half-circle wraparound bowl
itself is still deferred to v5.5.2.

**Floor lowered.** `SEED_POOL_DEPTH` 20→33; floor moves from
z=−37 → z=−50. Reason: disc-with-teeth lowest world Z at α=270° is
−47.76 mm (back-face teeth). Old floor at −37 sat 10.76 mm ABOVE the
teeth, requiring `disc_envelope_above_floor` to clip the disc-cut
half-space (otherwise teeth carved a slot through the floor). New
floor sits 2.24 mm BELOW the teeth → disc clears the floor in the
mesh and the validation check passes without the half-space hack.
The half-space clip is kept defensively (cheap insurance against
future teeth-OD growth).

**V-cone in Y.** Added `SEED_POOL_BOTTOM_Y = 4` (was implicitly =
inner_y = 36 — the bottom strip was a long ridge, not a cone). Now
the cavity is a true 4×4 mm bottom widening to 56×36 at the top.
Wall slopes:
- X-wall: atan((28−2)/33) = 38.2° (was 36.9°) — still ≥35°.
- Y-wall: atan((18−2)/33) = 25.9° in body, but bottom strip narrows
  Y to 4 → effective floor-up Y slope atan((36−4)/2 / 31) = 27.3°.
  This is BELOW the ≥35° spec target. Workable for soybeans (low
  rest angle) but flagged for v5.5.2 review — likely fix is
  narrowing top Y or further lowering bottom_y.
- `SEED_POOL_BOTTOM_X` 6→4 (matches BOTTOM_Y; tighter pickup lane).

**STL re-export**: 899v/1810f → 985v/1982f. Bounds: x[−30,+30]
unchanged; y[−82.79,−10] unchanged; z[−50, +55.97] (floor moved
−13). Watertight. Copied to `viewer/models/`.

**Validation**: `disc_above_floor` now PASSES — no disc surface
samples within 1 mm of pool floor (z=−50). All other six checks
PASS at (60.00, −50.00, 55.97, −10.00, −82.79). Updated
`SEED_POOL_DEPTH=33` and `SEED_POOL_Z_FLOOR=−50` constants in
`validation/geometry_check.py`.

**Iso render**: `renders/v5_2/v5_5_1_iso.png` shows narrower V-cone
profile through the front wall.

**Tag**: v5.5.1.

---

## V5.5.2 — half-disc footprint pool, wraps disc bottom 180° (2026-04-27)

Stage B of Hendrik's Phase-5 spec: the rectangular 60×40 pool becomes a
half-disc (radius 55, opening at y=0, footprint y ≤ 0). Wraps the disc
bottom 180° in plan view — any seed detaching mid-travel whose XY
projection lands in the half-disc footprint is now caught by the pool.

**Footprint change.** Body geometry switched from
`cube([60, 40, 33])` to `difference(){ cylinder(r=55,h=33); cube(y>0 half) }`.
Cavity follows the same pattern: hull from a half-disc of radius
R_INNER=53 (top opening) down to the existing 4×4 mm V-cone patch at
(0, -30, floor+2). Floor still z=-50, top still z=-17.

**Why R=55.** Sized to keep the existing tube anchors INSIDE the body:
- feeder anchor (15, -50, -22): radius √(15² + 50²) = 52.2 < 55 ✓
- vac    anchor (0, -42, -43): radius 42 < 55 ✓
Both tubes still emerge through the pool wall (now curved instead of
flat) — the tube body's back end overlaps the wall by SEED_POOL_WALL+EPS,
union stays watertight, bore pierces through to the cavity.

**Wall slopes.** With V-cone at (0, -30, -48) and half-disc top R=53:
- Front edge (toward -Y): bottom (0,-30,-48) → top (0,-53,-16). Slope
  atan(32/23) = **54°** ✓
- Back edge (toward +Y): bottom (0,-30,-48) → top (0,0,-16). Slope
  atan(32/30) = **47°** ✓
- Side edges (toward ±X): bottom (0,-30,-48) → top (±53,0,-16).
  Slope atan(32/√(53²+30²)) = **28°** ⚠ below ≥35° spec.

The shallow side slope is a known limitation of the half-disc shape
+ single-point V-cone. Soybeans (rest angle ~25-30°) will roll on
28° but it's tighter than ideal. Mitigations for v5.5.3+:
1. Replace single V-cone with a curved trough following the disc rim
   path projection — seeds drain along the disc-bottom arc.
2. Tighten R_OUTER to ~40 (gives ~38° side slopes) at the cost of
   smaller catch area.
3. Add a rim-following internal rib to break the long side slope.

**Disc-envelope subtraction unchanged.** The disc rim with teeth
crosses the half-cylinder pool wall at world-XY radius 55 at z=-36.5
(two crossings per side, at θ_disc=231°/309° on the bottom-half).
The clipped disc envelope (z ≥ floor+1) carves a slot through the
curved wall at these crossings — same mechanic as the rectangular
pool's left/right wall slots.

**STL**: 985v/1982f → 1143v/2294f. Bounds: x[−55, +55] (was [−30,+30]),
y[−82.79, 0] (was [−82.79, −10]), z[−50, +42.97] unchanged.
Watertight. Copied to `viewer/models/`.

**Validation**: replaced `y_back_face` check (was y_max≈-10) with
`y_back_edge` (y_max≈0, the half-disc opening). Updated
`x_extent_with_tubes` to 2·R_OUTER=110 and `y_front_or_further` to
≤ -R_OUTER=-55. All seven pool/clearance checks PASS at
(110.00, −50.00, 42.97, 0.00, −82.79).

**Iso render**: `renders/v5_2/v5_5_2_iso.png`.

**Deferred to v5.5.3+** (per Hendrik's full Phase-5 spec):
- Drainage rib / curved bottom trough for ≥35° slopes everywhere
- "Clean cycle" UI button + vacuum-suction animation
- Seed-loss tracking visualisation (prove zero seed loss between lines)

**Tag**: v5.5.2.

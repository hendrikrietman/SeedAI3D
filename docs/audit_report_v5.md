# V5 Audit Report — 2026-04-28 (post-Phase-5)

> Read-only inventory of `~/workspace/protisem-v4/`. No code or geometry was
> changed during this audit; only this report file was rewritten.
>
> This is the **second** audit of the V5 tree. The first (earlier today)
> drove the v5.6.0 Phase-5 commit and is preserved in this file's git
> history if needed for comparison. Everything below reflects the state at
> commit `5bafb4c` / tag `v5.6.0` / tag `phase5-backup`.

## Summary

The repository is in a **clean post-Phase-5 state**: 16 commits, working
tree clean, two new tags (`v5.6.0`, `phase5-backup`). Phases 1–5 are
implemented in code with matching SCAD + STL pairs; the entire validation
suite (36/36 checks) passes. **Phase 6 (gear drive + motor mount) has not
been started** — no parameters, no SCAD source, no STL, no viewer wiring.
That is expected; Hendrik asked for the backup tag *before* Phase 6.

The drift items the previous audit flagged have all been closed:
- Viewer `POOL` block now uses half-disc geometry (R_OUTER=55, depth 33,
  floor −50) consistent with `parameters.scad`.
- Stale `stl/v4_2/{disc,reservoir}.stl` removed from the tree.
- `decisions.md` gained D8 (V5 FLIP), D9 (vacuum-respecting glide),
  D10 (half-disc pool footprint).

The only remaining caveat: Phase-5 changes have **not been visually
verified in a browser** in this build environment (no display).

## File inventory

```
~/workspace/protisem-v4/

scad/
  lib/helpers.scad                  1.2 KB    2026-04-27 16:01
  lib/parameters.scad              15.0 KB    2026-04-28 15:43   ← Phase 5 added
  v4_1_disc.scad                    2.6 KB    2026-04-27 16:01
  v5_2_seed_pool.scad               8.8 KB    2026-04-27 21:31
  v5_3_barriere_geleider.scad       9.9 KB    2026-04-27 19:37
  v5_4_vacuum_chamber.scad          7.4 KB    2026-04-27 19:34
  v5_5_recovery_bowl.scad           6.9 KB    2026-04-28 15:44   ← NEW

stl/
  v4_1/disc.stl                     2.3 MB    2026-04-27 18:54
  v5_2/disc.stl                     2.3 MB    2026-04-27 18:55
  v5_2/seed_pool.stl              430.4 KB    2026-04-27 21:31
  v5_3/afstrijker.stl               2.4 KB    2026-04-27 19:38
  v5_3/afstrijker2.stl              2.3 KB    2026-04-27 19:38
  v5_3/geleider.stl                80.7 KB    2026-04-27 18:03
  v5_3/drop_tube.stl               82.4 KB    2026-04-27 18:01
  v5_4/vacuum_chamber.stl         150.0 KB    2026-04-27 19:35
  v5_5/recovery_bowl.stl           98.1 KB    2026-04-28 15:44   ← NEW
  (stl/v4_2/ deleted in v5.6.0)

viewer/
  index.html                        4.5 KB    2026-04-28 15:49
  viewer.js                        38.4 KB    2026-04-28 15:51   ← +clean cycle, POOL fix
  styles.css                        1.8 KB    2026-04-28 15:49   ← +.btn class
  package.json + package-lock.json + node_modules/three (vendored)
  vendor/three.module.js + vendor/addons/ (importmap targets)
  models/
    disc.stl                        2.3 MB    2026-04-27 18:59
    seed_pool.stl                 430.4 KB    2026-04-27 21:33
    afstrijker.stl + afstrijker2.stl
    geleider.stl
    drop_tube.stl
    vacuum_chamber.stl
    recovery_bowl.stl              98.1 KB    2026-04-28 15:47   ← NEW

validation/
  geometry_check.py                23.8 KB    2026-04-28 15:52   ← +check_recovery_bowl

docs/
  build_log.md                     38.4 KB    2026-04-28 15:54   ← +V5.6.0 entry
  decisions.md                     16.0 KB    2026-04-28 15:53   ← +D8/D9/D10
  audit_report_v5.md               17.6 KB    2026-04-28 15:35   ← rewritten by this audit

renders/
  v4_1/  4 PNG (Phase-1 disc)
  v4_2/  4 PNG (V4 era — still on disk; the SCAD source was retired)
  v5_2/  3 PNG (assembly + v5.5.1 + v5.5.2 iso)
  v5_4_anchor/  3 PNG (chamber anchor verification)
  v5_5/  v5_5_iso.png  183.7 KB  2026-04-28 15:47   ← NEW

scripts/
  render_all.sh                     1.6 KB
  update_viewer.sh                  0.5 KB
```

## Phase status

### Phase 1 — Disc
- SCAD: **present** (`scad/v4_1_disc.scad`)
- STL: **present** (`stl/v4_1/disc.stl`, copied to `viewer/models/`)
- `PICKUP_HOLE_DIA = 4.0 mm`  ✓ (per Phase-4 spec; soybean Ø~6 mm cannot pass)
- `PICKUP_HOLE_COUNT = 40`    ✓
- `DISC_TILT_DEG = 45°`       ✓
- Status: **complete, unchanged since first audit**

### Phase 2 — Reservoir / pool
- V4 top-funnel reservoir: **retired** (no SCAD source, no orphan STLs anymore)
- V5 bottom seed-pool: **active**, `scad/v5_2_seed_pool.scad`
  - Half-disc body, R_OUTER=55, footprint y ≤ 0
  - V-cone bottom 4×4 mm at (0, −30, floor+2), floor z=−50
  - Front-mount feeder tube (OD 18, ID 14, 60° elev) included
  - Top-mount vac-cleanup tube (OD 26, ID 22, 80° elev) included
- Status: **complete, unchanged since first audit**

### Phase 3 — Afstrijkers + geleider + animation
- Afstrijker 1 at θ=250° (singulator, height 8): **present** ✓
- Afstrijker 2 at θ=95° (release pusher, height 6): **present** ✓
- Geleider catch-mouth 40×20 at z=20, y_centre=30: **present** ✓
- Drop-tube OD 30 / ID 24, z_top=−6, z_bottom=−52: **present** ✓
- 6-state seed-lifecycle animation (pool → attached → falling → gliding →
  exiting → landed) with HUD counters: **implemented** ✓
- Status: **complete, unchanged since first audit**

### Phase 4 — Vacuum chamber
- Annular sector (R_in=30, R_out=50, depth 8, sector θ ∈ [90°, 270°]
  through 180°, world x ≤ 0): **present** ✓
- Ø 12 hose nipple, length 30 mm: **present** ✓
- Air gap 1.5 mm between disc and back-wall: implemented as
  `EPS = 0.01` slight inset at the disc-side opening (chamber's "front"
  is the disc back face); the seal is implicit at R=30 and R=50.
- **Boog-vormige rubber seal**: **not a separate modeled part**. The
  spec calls for a curved O-ring at R=30 and R=50; current SCAD leaves
  this as an implicit interface to be added in BOM/printing. Flagged
  but acceptable for digital geometry.
- Status: **structurally complete; seal element implicit (BOM concern)**

### Phase 5 — Recovery bowl + dual tubes + clean cycle
- Half-circle bowl around disc TOP half: **present** ✓ (NEW in v5.6.0,
  `scad/v5_5_recovery_bowl.scad`, `stl/v5_5/recovery_bowl.stl`).
  Half-disc shell, footprint y ≥ 0, R_OUTER=55, z ∈ [22, 50]. Floor
  flush on the geleider top with a 40×20 drain at y=30 aligned to the
  geleider catch-mouth. Disc-envelope subtraction (3 mm clearance)
  carves the slot where the rim crosses the outer wall.
- Feeder tube 60° from front: **present** ✓
- Vac-cleanup tube 80° from top: **present** ✓
- Self-cleaning animation button: **present** ✓ (NEW in v5.6.0).
  "Start clean cycle" button in the controls panel toggles
  `cleanCycleActive`. While active: vacuum forced to 0 internally,
  pool refill suppressed, pool seeds animated through the vac-cleanup
  tube at 3/s into a new "Cleaned" HUD counter.
- Status: **complete in code, awaiting browser eyeball verification**

### Phase 6 — Aandrijving + motor (gear drive + motor mount)
- BLDC motor mount: **MISSING**
- Drive pinion (20 teeth): **MISSING**
- Engagement with disc tooth-rim (60 teeth): **MISSING**
- Motor angle (45°): **N/A** (motor not yet placed)
- Motor rotation animation synchronous with disc: **N/A** (motor not yet present)
- No `parameters.scad` entries for `MOTOR_*` / `PINION_*`
- No `scad/v5_6_*.scad` source file
- No `stl/v5_6/` directory
- No viewer mesh load or toggle for motor / pinion
- Status: **not started — expected; Hendrik tagged `phase5-backup` first**

## Viewer state

`index.html` and `viewer.js` are loaded together via an importmap pointing
at `./vendor/three.module.js` and `./vendor/addons/`. Title now reads
"PROTISEM V5 — Phase 5 (recovery bowl + clean cycle)".

### STL meshes loaded (cache-busted with `?v=${Date.now()}`)
- `disc.stl`            — PETG-blue, rotates around `DISC_AXIS`
- `seed_pool.stl`       — translucent grey
- `afstrijker.stl` + `afstrijker2.stl` — dark grey
- `geleider.stl`        — translucent dark
- `drop_tube.stl`       — translucent dark
- `vacuum_chamber.stl`  — translucent dark blue
- `recovery_bowl.stl`   — translucent yellow-amber (NEW)

Procedural groups: pool-fill seeds (target 50, refill at <12), attached
seeds, falling/gliding/exiting/cleaning seeds (5 distinct materials),
pickup/release marker spheres, 40 per-hole vacuum-glow markers.

### UI toggles (controls panel, top-left)
1. RPM slider 0–30 (default 5.0)
2. Vacuum slider 0–100 (default 80)
3. Cross-section (cut +X half)
4. Pickup / release markers
5. Seed-pool fill
6. Seeds on disc (red)
7. Afstrijker 1 (pickup singulator)
8. Afstrijker 2 (release pusher)
9. Geleider (catch chute)
10. Drop-tube
11. Vacuum-kamer (transparant)
12. Vacuum-glow (active hole markers)
13. **Recovery bowl (top-half catch)** — NEW in v5.6.0
14. **"Start clean cycle" button** — NEW in v5.6.0

### State counters (info panel, top-right)
- Rotation angle
- Pool seeds
- On disc
- In geleider
- In drop-tube
- Sown (cum.)
- Skipped (cum.)
- Missed (cum.)
- **Cleaned (cum.)** — NEW in v5.6.0

### Animation
Implemented in `requestAnimationFrame` loop (`animate()`). Seed lifecycle:
pickup at θ=270° → travel on disc-front face → vacuum-respecting glide
to drop-tube at θ=90° → land. Singulator slip 5%, push-pusher 10%,
vacuum<5 → free-fall. Anchor verification logs PASS/FAIL on every STL
load. **fps not measurable in this audit environment** — the build
environment has no display; needs a browser run.

## Inconsistencies detected

### Carried-over from first audit — all resolved in v5.6.0

1. **Viewer `POOL` block stale**: closed. `viewer.js:97-105` now declares
   `{ rOuter: 55, wall: 2, depth: 33, zTop: -17, zFloor: -50, yCenter: -30,
   fillZ: -24 }`, matching `parameters.scad`. `placePoolSeed()` rewritten
   to spawn within the half-disc footprint with chord-bound x range.
2. **Stale V4 STLs**: closed. `stl/v4_2/{disc,reservoir}.stl` deleted via
   `git rm`; the (now-empty) directory is gone from the tree.
3. **`decisions.md` lag**: closed. D8 (FLIP), D9 (vacuum-respecting glide),
   D10 (half-disc pool) backfilled.

### Hardcoded values in viewer.js

The following geometric constants are hardcoded in `viewer.js`. All
values **match** `parameters.scad`. The viewer has no SCAD parser; this
is the intentional architecture (vendored constants kept in sync):
- `TILT = π/4`, `R_PICKUP = 42`, `N_HOLES = 40`, `SEED_RADIUS = 3`
- `PICKUP_THETA = 270°`, `RELEASE_THETA = 90°`
- `AFSTRIJKER_THETA = 250°`, `AFSTRIJKER2_THETA = 95°`
- `AFSTRIJKER_SLIP_PROB = 0.05`, `AFSTRIJKER2_PUSH_PROB = 0.10`
  (these are visualisation-only probabilities, not geometry; SCAD has
   matching values for documentation but nothing imports them)
- `GELEIDER`, `DROP_TUBE`, `POOL`, `BOWL` blocks ✓
- `DISC_THICKNESS = 4`, `AFS_HEIGHT = 8`, `AFS2_HEIGHT = 6` ✓
- `VAC_CLEAN_MOUTH = (0, -42, -43)`, `VAC_CLEAN_DIR` from 80° elev ✓
- `CLEAN_RATE = 3.0` (visualisation-only, no SCAD equivalent)

No drift detected.

### SCAD-vs-SCAD contradictions

None. Single canonical version of each component:
`v4_1_disc.scad` (Phase 1) → `v5_2_seed_pool.scad` (Phase 2 V5) →
`v5_3_barriere_geleider.scad` (Phase 3) → `v5_4_vacuum_chamber.scad`
(Phase 4) → `v5_5_recovery_bowl.scad` (Phase 5).
The retired V4 reservoir SCAD is not on disk (per D6).

### Phase 4 vacuum chamber

It works. Anchor verification (`viewer.js:472-484`) reports PASS for the
chamber STL centroid against the expected `(-26.67, +6.67, -6.67)`
post-FLIP position with `disc_plane_eq < 0` (back side). Earlier renders
are saved in `renders/v5_4_anchor/{front,iso,side_x}.png`.

### Seed position offset

The audit prompt says "5 mm offset langs FRONT_NORMAL". The code uses
`SEED_RADIUS = 3 mm` (`viewer.js:165`, `viewer.js:826`). Reasoning
(`viewer.js:124-126`): seed Ø=6 mm sits with its near pole tangent to
the disc-front face around the 4 mm hole, so seed-centre offset =
SEED_RADIUS = 3 mm. Geometrically correct; the prompt's "5 mm" appears
to be a misremember from an older revision. Same observation as the
first audit; **not changed**.

### Phase-5 specific notes

- Recovery bowl `disc_clearance` validation passes at min=2.92 mm vs
  nominal 3.00, with a 0.15 mm tolerance to absorb the OpenSCAD `$fn=64`
  chord error at R=66 (R·(1−cos(π/$fn)) ≈ 0.08 mm). Geometrically
  correct; the gap is faceting noise, not interference.
- Bowl floor at z=22 has an intentional slot in y∈[19.2, 24.8] where
  the disc body slab |z−y|≤2.83 passes through — same kind of slot the
  bottom pool has (D6) and the geleider has (D7). The slot leaks; real
  hardware will need rim-following sealing brushes, deferred.
- The bowl catches seeds in the y > 0 half-plane between roughly θ=90°
  and θ=120° release (where vacuum drop on the upper arc would deposit
  a seed). The y < 15 floor region is reachable but unlikely to receive
  seeds in normal operation.

### Air gap on vacuum chamber

The Phase-4 spec reads "1.5 mm air gap tussen disc en static back-wall".
The current SCAD uses `EPS = 0.01 mm` inset at the chamber-front /
disc-back interface. There is no explicit 1.5 mm gap modelled. Reading
of the original spec is ambiguous: the gap could be a mechanical
clearance for the rotating disc, or a design parameter for the seal.
Current model assumes the disc back face IS the chamber front cover
(zero gap, sealed by O-rings at R=30 and R=50). If Hendrik wants a
non-zero gap modelled, that would be a separate clarification before
Phase 6.

## Build log status

`docs/build_log.md` (655 → 715 lines) now covers:
- Phase 1 — Parametric disc + viewer bootstrap
- Phase 2 — Reservoir + viewer integration (V4 funnel, retired)
- Phase 2 fix — pickup/release θ correction
- Phase 2 V5 — architecture switch to vacuum bottom-pool (D6)
- Phase 3 V5 — afstrijker + geleider + lifecycle animation
- Phase 3 V5 visual fixes — seed offset, raised pool, release pusher
- Phase 3 V5 fix — `FRONT_NORMAL` derived from pool reference
- Phase 4 V5 — vacuum chamber + 4 mm holes + corrected seed mechanics
- V5 anchor-based verification
- V5 FLIP — seeds and chamber side-swap
- V5 polish — vacuum-respecting glide + front-face tube ports
- V5.5.0 — wider feeder + vac tube relocated to top
- V5.5.1 — V-cone in both X & Y, floor lowered
- V5.5.2 — half-disc footprint pool, wraps disc bottom 180°
- **V5.6.0 — Phase 5: top-half recovery bowl + clean-cycle animation** (NEW)

`docs/decisions.md` (132 → 248 lines) now contains 10 numbered decisions:
D1 (tilt axis), D2 (Phase-1 open items), D3 (three.js vendoring),
D4 (reservoir outlet — historical), D5 (θ=110/70 — superseded),
D6 (V5 architecture), D7 (geleider throat below disc-body slab),
**D8 (V5 FLIP)**, **D9 (vacuum-respecting glide)**, **D10 (half-disc pool)**.

What's not yet documented:
- Phase 6 architectural decisions (motor placement, gear ratio, mount
  attachment to housing). Will be written when Phase 6 starts.

## Git status

- Branch: `master`, working tree clean
- 16 commits since `Phase 0: scaffolding`
- Latest commit: `5bafb4c v5.6.0: Phase 5 — top-half recovery bowl +
  clean-cycle animation` (2026-04-28 15:56 UTC, today)
- Tags: `v4.1`, `v5.2`, `v5.3`, `v5.3.1`, `v5.4`, `v5.4.2`, `v5.4.3`,
  `v5.5.0`, `v5.5.1`, `v5.5.2`, **`v5.6.0`**, **`phase5-backup`** (last two NEW)
- `phase5-backup` is the explicit rollback point Hendrik requested before
  Phase 6 begins. `git reset --hard phase5-backup` restores the tree.

## What's complete

- Phases 1–5 all have SCAD source + STL output + viewer integration.
- All 36 validation checks PASS:
  - Phase 1 disc: 5 checks
  - Phase 2 V5 pool + clearance: 8 checks
  - Phase 3 afstrijkers + geleider + drop-tube: 12 checks
  - Phase 4 chamber: 4 checks
  - Phase 5 recovery bowl: 7 checks
- 6-state seed lifecycle animation runs with HUD counters
  (pool / on-disc / in-geleider / in-drop-tube / sown / skipped / missed
  / cleaned).
- Self-cleaning UI cycle implemented in viewer (button + state machine).
- Anchor-based verification gates every STL load with PASS/FAIL log.
- Backup tag `phase5-backup` exists; clean working tree.

## What's incomplete or broken

- **Phase 6 not started**: motor mount, drive pinion (20T), gear engagement
  geometry, motor rotation animation. None of: SCAD source, STL,
  parameters, viewer wiring. Expected per Hendrik's instruction.
- **Phase 5 browser eyeball not done**: recovery bowl visual, clean-cycle
  animation, and updated pool-seed spawn pattern all need a human at the
  viewer before Phase 6 starts. Build environment has no display.
- **Vacuum chamber rubber seal**: not a separate modeled part. Implicit
  at chamber-wall / disc-back-face contact line at R=30 and R=50.
  Acceptable for digital geometry, flag for BOM.
- **Air gap on chamber**: the original Phase-4 spec mentioned 1.5 mm
  air gap; current model uses 0.01 mm EPS inset (effectively zero).
  Re-confirm with Hendrik whether a 1.5 mm gap should be modelled.
- **Bowl/pool/geleider rim slots leak**: every component that the disc
  passes through has an envelope-subtraction slot. Real hardware needs
  rim-following sealing brushes (Monosem-style). Deferred consistently
  across D6, D7, and the new bowl. Not a Phase-5/6 blocker.
- **Recovery bowl floor in y < 15 region**: bowl floor is flat, so seeds
  bouncing into the y ∈ [0, 15] zone at z=22 just sit there until the
  next clean cycle. Acceptable trade-off; could be sloped toward the
  drain in a future revision if real-world testing shows accumulation.

## What needs fixing before Phase 6

1. **Browser eyeball pass** on the v5.6.0 viewer:
   - Open `http://localhost:8000/` (or whatever port `python3 -m
     http.server -d viewer` is running on).
   - Hard-reload (Ctrl/Cmd-Shift-R) to bypass the JS/HTML/CSS cache.
   - Confirm: recovery bowl renders as translucent yellow-amber on the
     disc top half; clean-cycle button drains the pool while the
     "Cleaned" counter ticks at ~3/s; pool seeds spawn within the
     half-disc footprint not the old rectangle; nothing visibly
     interferes with the disc rim.
2. **Decide on chamber air gap** (1.5 mm or 0). If non-zero, that's a
   small `parameters.scad` + `v5_4_vacuum_chamber.scad` change, ideally
   done before Phase 6 since the gear pinion will mechanically reference
   the same disc-back area.
3. **Phase 6 design questions to resolve before coding** — not blocking
   this audit, but worth lining up:
   - Motor placement: where does the BLDC sit relative to the disc rim?
     The disc tilts 45°, teeth are on the rim — pinion axis must be
     parallel to the disc plane, not vertical. Default: pinion engages
     at θ=0° (rim point world (66, 0, 0)) with pinion axis along Y'
     (the in-plane perpendicular).
   - Gear ratio: 20T pinion / 60T disc = 3:1 reduction (per CLAUDE.md).
     BLDC NEMA17 typical 3000–5000 rpm → disc 1000–1700 rpm before
     reduction; with 3:1 → disc 17–28 rpm. Matches the viewer's 0–30
     RPM slider range — no further reduction needed.
   - Mount attachment: housing wall at the +X side at z=0 — but the
     housing module isn't built yet. Phase 6 will need either a
     simplified standalone bracket or a placeholder housing wall.

## Recommended next steps

1. **Hendrik runs the browser eyeball pass**. Confirms 5a/5b work
   visually. If anything is off, ping me with what you see.
2. **Hendrik decides on the chamber air gap** (1.5 mm or keep at zero).
3. **Then start Phase 6** in this order:
   - 6a. Add `MOTOR_*` and `PINION_*` parameters to `parameters.scad`.
   - 6b. New `scad/v5_6_gear_drive.scad` — pinion + simple motor body
     box + minimal mount bracket.
   - 6c. STL exports to `stl/v5_6/`, viewer mesh loads.
   - 6d. Wire pinion rotation in viewer animation: `pinion.rotation =
     -disc_rotation × 60/20 = -3·rotationAngle` around the in-plane
     perpendicular.
   - 6e. Validation: `check_pinion()` for tooth count, OD, axis
     alignment. Anchor-verify the pinion centroid sits on the rim
     engagement point.
   - 6f. Commit `v5.7.0`, optionally tag a `phase6-backup` for the
     same reason this `phase5-backup` exists.
4. **Open project decisions** still unresolved from `CLAUDE.md`:
   - Phase 7 bearing choice (edge rollers default per D2.1).
   - Print material PETG (fixed per D2.3).
   - First physical print after Phase 3 was the original recommendation
     — re-confirm now that Phase 5 is in.
   None block Phase 6 start.

# V5 Audit Report — 2026-04-28

> Read-only inventory of the protisem-v4 working tree. **No code or geometry
> was modified during this audit.** Hendrik decides next steps from this
> report.

## Summary

The repository is in a **coherent, fully-committed state at tag/commit
`v5.5.2`** (15 commits, working tree clean). Phases 1–4 ship with both SCAD
sources and matching STL outputs; Phase 5 has been **partially anticipated**
by the v5.5.0–v5.5.2 commits (front-mount feeder tube, top-mount vac-cleanup
tube, half-disc pool footprint), but the **top-half recovery bowl and the
self-cleaning animation explicitly listed in the Phase-5 spec are not built**.
Two stale-state issues stand out: the viewer's `POOL` block hard-codes pre-v5.5
geometry (rectangular 60×40, floor at z=−37) that no longer matches the
authoritative `parameters.scad`, and a few orphan STLs from V4 still live
under `stl/v4_2/`.

The actual workdir is `~/workspace/protisem-v4/` — there is no `protisem-v5/`
folder. V5 lives inside the v4 tree (deliberate, per `CLAUDE.md`).

## File inventory

```
~/workspace/protisem-v4/

scad/
  lib/helpers.scad                 1.2 KB    2026-04-27 16:01
  lib/parameters.scad             13.7 KB    2026-04-27 21:31   ← authoritative
  v4_1_disc.scad                   2.6 KB    2026-04-27 16:01
  v5_2_seed_pool.scad              8.8 KB    2026-04-27 21:31
  v5_3_barriere_geleider.scad      9.9 KB    2026-04-27 19:37
  v5_4_vacuum_chamber.scad         7.4 KB    2026-04-27 19:34

stl/
  v4_1/disc.stl                    2.3 MB    2026-04-27 18:54
  v4_2/disc.stl                    2.3 MB    2026-04-27 16:25   ← stale (V4)
  v4_2/reservoir.stl              74.6 KB    2026-04-27 16:46   ← stale (V4)
  v5_2/disc.stl                    2.3 MB    2026-04-27 18:55
  v5_2/seed_pool.stl             430.4 KB    2026-04-27 21:31
  v5_3/afstrijker.stl              2.4 KB    2026-04-27 19:38
  v5_3/afstrijker2.stl             2.3 KB    2026-04-27 19:38
  v5_3/geleider.stl               80.7 KB    2026-04-27 18:03
  v5_3/drop_tube.stl              82.4 KB    2026-04-27 18:01
  v5_4/vacuum_chamber.stl        150.0 KB    2026-04-27 19:35

viewer/
  index.html                       4.2 KB    2026-04-27 19:04
  viewer.js                       38 KB · 919 lines  2026-04-27 ~21:00
  styles.css                       (present, not inspected)
  package.json + node_modules/three  (vendored r150+)
  vendor/                          (three module + addons import-map target)
  models/
    disc.stl                       2.3 MB    2026-04-27 18:59
    seed_pool.stl                430.4 KB    2026-04-27 21:33   ← matches stl/v5_2
    afstrijker.stl + afstrijker2.stl
    geleider.stl
    drop_tube.stl
    vacuum_chamber.stl

validation/
  geometry_check.py               20.5 KB    2026-04-27 21:34   ← mirrors parameters.scad

docs/
  build_log.md                    35.5 KB    655 lines  2026-04-27 21:36
  decisions.md                    11.4 KB    132 lines  2026-04-27 18:11

renders/
  v4_1/  (4 PNG snapshots: cross, cross_section, front, iso)
  v4_2/  (4 PNG snapshots — V4 era)
  v5_2/  (3 PNG: assembly_cross_section, v5_5_1_iso, v5_5_2_iso)
  v5_4_anchor/  (3 PNG: front, iso, side_x — chamber anchor verification)

scripts/
  render_all.sh                    1.6 KB
  update_viewer.sh                 0.5 KB
```

## Phase status

### Phase 1 — Disc
- SCAD: **present** (`scad/v4_1_disc.scad`)
- STL: **present** (`stl/v4_1/disc.stl`, also re-exported into `viewer/models/`)
- `PICKUP_HOLE_DIA = 4.0 mm`  ✓ (matches Phase-4 update; soybean Ø ~6 mm cannot pass)
- `PICKUP_HOLE_COUNT = 40`    ✓
- `DISC_TILT_DEG = 45°`       ✓
- `DISC_OD = 120`, `DISC_OD_WITH_TEETH = 132`, `DISC_THICKNESS = 4` ✓
- Status: **complete**

### Phase 2 — Reservoir / pool
- V4 top-funnel reservoir: **retired**. There is no `v4_2_reservoir.scad`
  source on disk. Only orphan STLs `stl/v4_2/{disc,reservoir}.stl` remain.
- V5 bottom seed-pool: **active**, source = `scad/v5_2_seed_pool.scad`.
  Recent v5.5.x revisions changed the footprint from rectangular 60×40 to a
  **half-disc** (R_OUTER = 55, opening at y = 0, footprint y ≤ 0), with a
  4×4 mm V-cone bottom centred at (0, −30, floor + 2) and floor lowered to
  z = −50.
- The half-disc body **wraps the disc bottom 180° in plan view**, not the top.
- Front-mount feeder tube (OD 18, ID 14, 60° elev) and top-mount vac-cleanup
  tube (OD 26, ID 22, 80° elev = 10° off vertical) are part of this file.
- Status: **complete for the bottom-half pool/feeder/vac-cleanup**.

### Phase 3 — Afstrijkers + geleider + animation
- `AFSTRIJKER_THETA_DEG = 250` (singulator, height 8): **present**, STL `2.4 KB`
- `AFSTRIJKER2_THETA_DEG = 95` (release pusher, height 6): **present**, STL `2.3 KB`
- Geleider catch-mouth (40 × 20 at z = 20, y_centre = 30): **present**
- Drop-tube (OD 30, ID 24, z_top = −6, z_bottom = −52, through central 50 mm hole): **present**
- Six-state seed-lifecycle animation (pool → attached → falling → gliding →
  exiting → landed): **implemented in `viewer.js`** with HUD counters for
  pool/onDisc/inGeleider/inTube/sown/skipped/missed.
- Status: **complete**

### Phase 4 — Vacuum chamber
- Annular sector body (R_in = 30, R_out = 50, depth 8, sector covers
  disc-local θ ∈ [90°, 270°] — i.e. the world x ≤ 0 half): **present**
- Ø 12 hose nipple at θ = 180°, length 30 mm: **present** (model + parameter)
- Wall thickness 2 mm; outer + inner cylinder + back plate + end-walls form
  the hollow shell; disc-back face is the front cover.
- Anchor-based verification (`viewer.js` lines 393–470) confirms post-flip
  centroid sits in `disc_plane_eq > 0` (back-side, opposite of seeds), tol 2 mm.
- **Air-gap rubber-seal element**: an explicit O-ring/seal part is **NOT
  modeled**. The build log notes the seal is implicit at the chamber-wall /
  disc-back-face contact line at R = 30 and R = 50; real hardware will need
  PTFE/rubber rings. Acceptable for digital geometry; flag for BOM later.
- Status: **structurally complete; rubber seal is implicit, not a separate part**

### Phase 5 — Recovery bowl + self-cleaning
The user-quoted Phase-5 spec has four items. Current status:
- **Half-circle bowl around the disc TOP half**: **MISSING**. The existing
  half-disc body in `v5_2_seed_pool.scad` wraps the disc *bottom* (footprint
  y ≤ 0). A separate top-half catch bowl that wraps the *top* of the disc
  (to catch any seeds released other than at θ = 90°) does not exist.
- **Feeder tube 60° from front**: **present** (front face of pool).
- **Vac-cleanup tube 80° from top**: **present** (top of pool).
- **Self-cleaning animation button**: **MISSING**. No `Clean cycle` toggle
  in `index.html`; no corresponding state machine in `viewer.js`. Build log
  v5.5.2 entry explicitly defers this to v5.5.3+.

So Phase 5 is **~50% done** depending on how the spec is read. The
front/top tubes and the deeper pool exist; the top-half recovery bowl and
the self-cleaning UI/animation do not.

## Viewer state

`index.html` and `viewer.js` are loaded together via an import-map pointing
at `./vendor/three.module.js` and `./vendor/addons/`.

### Components rendered (all loaded with cache-bust query string)
- `disc.stl`            — PETG-blue, rotates around `DISC_AXIS = (0, −sin45°, +cos45°)`
- `seed_pool.stl`       — translucent grey
- `afstrijker.stl` (1)  — dark grey, near-opaque
- `afstrijker2.stl` (2) — same material
- `geleider.stl`        — translucent dark
- `drop_tube.stl`       — translucent dark
- `vacuum_chamber.stl`  — translucent dark blue

Procedurally added groups: pool-fill seeds (50 yellow spheres, refill at <12),
attached seeds (red, ride disc), falling/gliding/exiting seeds (separate
materials per state), pickup/release marker spheres (red/orange), per-hole
vacuum-glow markers (40 additive-blue spheres, visible only when vacuum>5
and hole is in the chamber sector x ≤ 0).

### UI toggles (left panel)
RPM slider 0–30 (default 5.0) · Vacuum slider 0–100 (default 80) ·
Cross-section (cut +X half) · Pickup/release markers · Seed-pool fill ·
Seeds on disc · Afstrijker 1 · Afstrijker 2 · Geleider · Drop-tube ·
Vacuum-kamer · Vacuum-glow.

### State counters (right panel)
Rotation angle, pool seeds, on disc, in geleider, in drop-tube, sown
(cumulative), skipped (cumulative), missed (cumulative).

### Animation
Implemented and runs in `requestAnimationFrame` loop (`animate()`). Time
slowed by `TIME_SCALE = 0.18` for visualisation. Seed lifecycle works:
- pickup at θ=270° (vacuum-on, pool not empty) → seed becomes "attached"
- afstrijker singulator slip 5%, afstrijker2 push 10%, otherwise natural
  release at θ=90°
- release uses **vacuum-respecting two-stage glide**: rim → above central
  axis (`pMid`), then vertical drop to `geleider.throat + 1`, then
  `captureToExiting` → drop-tube → `landSeed`. The free-fall path through
  the geleider catch-mouth still exists as a fallback (vacuum lost mid-cycle).
- if vacuum < 5: every attached seed detaches with v = 0 → counted as missed.

Could not render the viewer in a browser from this audit environment, but
the code paths are coherent and the anchor-verification block prints PASS/FAIL
to console at startup for each STL.

## Inconsistencies detected

### 1. Viewer `POOL` constants are stale (parameters.scad evolved past them)

`viewer/viewer.js:97-101` declares:
```js
const POOL = { x: 60, y: 40, depth: 20,
               zTop: -17, zFloor: -37, yCenter: -30,
               fillZ: -24 };
```
Authoritative `scad/lib/parameters.scad` says (after v5.5.0–v5.5.2):
- `SEED_POOL_DEPTH = 33`        (viewer says 20)
- `SEED_POOL_Z_FLOOR = -50`     (viewer says -37)
- `SEED_POOL_R_OUTER = 55`      (viewer has no R; uses rectangular 60×40)
- footprint is now half-disc (`y ≤ 0`), not rectangular

This only affects where pool-fill seeds are *spawned* in the viewer
(`placePoolSeed`), not the rendered STL geometry. Visually the spawned seeds
will sit ~13 mm above the actual pool floor and inside a footprint that
no longer matches the half-disc bowl. Worth correcting before Phase 5/6 so
new viewer logic doesn't multiply the drift.

### 2. Stale V4-era STLs

`stl/v4_2/disc.stl` (16:25) and `stl/v4_2/reservoir.stl` (16:46) have no
matching SCAD source — V4 reservoir architecture was retired in commit
`8f1f881` ("Phase 2 V5: architecture switch to vacuum-pickup bottom seed-pool
(D6)"). Safe to delete; flagged here, not removed.

### 3. Other geometric constants in viewer.js

Beyond the `POOL` block, all other hard-coded constants in `viewer.js`
**match** `parameters.scad`:
- `R_PICKUP = 42`, `N_HOLES = 40`, `TILT = π/4`, `SEED_RADIUS = 3` ✓
- `PICKUP_THETA = 270°`, `RELEASE_THETA = 90°` ✓
- `AFSTRIJKER_THETA = 250°`, `AFSTRIJKER2_THETA = 95°` ✓
- `AFSTRIJKER_SLIP_PROB = 0.05`, `AFSTRIJKER2_PUSH_PROB = 0.10` ✓
  (these intentionally live in viewer-only — they are visualisation
   probabilities, not geometry; SCAD has matching values for documentation
   but nothing imports them)
- `GELEIDER` and `DROP_TUBE` blocks ✓
- `DISC_THICKNESS = 4`, `AFS_HEIGHT = 8`, `AFS2_HEIGHT = 6` ✓

So the **only** geometry inconsistency is the pool block.

### 4. Phase 4 vacuum chamber *did* work

Anchor-based verification in `viewer.js` reports PASS (Δ ≤ 2 mm) for the
chamber STL centroid against the expected `(-26.67, +6.67, -6.67)` post-flip
position, with `disc_plane_eq > 0` (back side). Renders are saved under
`renders/v5_4_anchor/{front,iso,side_x}.png`.

### 5. Seed-position offset

Spec phrasing in this prompt: *"5 mm offset langs FRONT_NORMAL, op pool-side
van disc-plane"*. Actual `viewer.js`:
```js
state.seed.position = wp + FRONT_NORMAL · SEED_RADIUS    // SEED_RADIUS = 3 mm
```
Offset is **3 mm, not 5 mm**. Rationale (line 124): the seed (Ø 6 mm) sits
with its near pole tangent to the disc-front face around the 4 mm hole, so
seed-centre offset = SEED_RADIUS = 3 mm. The pool-side test
(`disc_plane_eq(seed) > disc_plane_eq(hole)` post-flip) is verified once at
runtime by `verifyFrontNormalOnce`. This is a discrepancy between the audit
prompt's recollection and what's in the code — flagging for Hendrik to confirm
the intended value.

## Build log status

`docs/build_log.md` (655 lines) covers:

- Phase 1 — Parametric disc + viewer bootstrap
- Phase 2 — Reservoir + viewer integration (V4 funnel)
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

Architectural decisions (`docs/decisions.md`, 132 lines) D1, D2, D3, D4, D5,
D6, D7. **No D8/D9/D10** — the most recent architectural turns
(V5 FLIP, vacuum-respecting glide, half-disc footprint) are documented in the
build log but **not promoted to numbered decisions**. Worth backfilling
before Phase 5/6 so the rationale is searchable.

## Git status

- Repository present, branch **`master`**, working tree **clean**.
- 15 commits since `Phase 0: scaffolding + project memory` (`11bdfe8`).
- Latest commit: `fa09bff v5.5.2: half-disc pool wraps disc bottom 180°`
  on 2026-04-27 21:37 UTC (i.e. yesterday).
- No uncommitted changes, no untracked files.

## What's complete

- Phase 1 — disc geometry, parameters, viewer bootstrap
- Phase 2 V5 — bottom seed-pool with V-cone bottom and front/top tubes
- Phase 3 V5 — afstrijker 1 + 2, geleider, drop-tube, full lifecycle animation
- Phase 4 V5 — vacuum chamber with hose nipple and anchor-verified placement
- v5.5.0–v5.5.2 — wider feeder, top-mount vac-cleanup, half-disc bottom pool
- Validation suite (`validation/geometry_check.py`) parameterised against
  `parameters.scad`
- Anchor-based STL verification on every load (logged to console)
- Git tagged after each milestone (15 commits, working tree clean)

## What's incomplete or broken

- **Phase 5 — top-half recovery bowl**: not modeled. The current half-disc
  pool wraps the disc bottom; a separate top-half catch bowl is missing.
- **Phase 5 — self-cleaning UI/animation**: no `Clean cycle` toggle in
  `index.html`; no corresponding state machine in `viewer.js`. Explicitly
  deferred to v5.5.3+ in the v5.5.2 build-log entry.
- **Viewer pool constants drift**: `viewer.js:97-101` still uses rectangular
  60 × 40, depth 20, floor −37 — three values that no longer match
  `parameters.scad` after v5.5.0–v5.5.2.
- **Stale V4 STLs**: `stl/v4_2/disc.stl` and `stl/v4_2/reservoir.stl` have no
  matching SCAD source.
- **Vacuum-chamber rubber seal**: not a separate modeled part. Implicit at
  the chamber-wall / disc-back-face contact at R = 30 and R = 50. Acceptable
  in digital model; flag for BOM and physical print.
- **Decisions doc lags build log**: V5 FLIP, vacuum-respecting glide,
  half-disc footprint not promoted to numbered architectural decisions.
- **Side-wall slope of bottom pool is 28°**, below the ≥35° self-feeding
  spec. Documented and known, deferred to v5.5.3+.
- **Disc rim still penetrates the pool side wall** (slot is carved by
  envelope subtraction). Sealing brushes will be needed in physical hardware;
  this is geometry-by-design for now.
- **Seed-position offset discrepancy**: prompt says 5 mm, code uses 3 mm
  (= SEED_RADIUS). Confirm intended value before Phase 5 changes anything.

## What needs fixing before Phase 5/6

1. **Update `viewer.js:97-101` POOL block** to mirror current
   `parameters.scad` (depth 33, floor −50, R_OUTER 55, half-disc footprint
   `y ≤ 0`). One file, ~10 lines. Required so the new Phase-5 self-cleaning
   animation isn't built on top of stale spawn coordinates.
2. **Decide top-half recovery bowl scope** for Phase 5: is it a separate
   half-cylinder (R≈55, footprint y ≥ 0) catching mis-released seeds at the
   disc top, or is it folded into the existing geleider mouth? This shapes
   the SCAD module structure.
3. **Decide self-cleaning animation scope**: states, UI button placement,
   counter (does cleaned-out seed count toward `sown` or new `cleaned`?).
4. **Optional but cheap**: prune `stl/v4_2/` orphans; backfill D8/D9/D10
   into `decisions.md` so Phase 5/6 can reference numbered decisions.
5. **Confirm seed offset** (3 vs 5 mm) — single-line change in `viewer.js`
   if the audit prompt was authoritative.

## Recommended next steps

1. **Hendrik confirms** the POOL drift fix, the seed-offset value, and
   whether the top-half recovery bowl is a Phase-5 must-have or a Phase-5b.
2. Quick-win cleanup commit: align viewer `POOL` constants, delete the two
   stale `stl/v4_2/*.stl` files, backfill three numbered decisions
   (FLIP, vacuum-respecting glide, half-disc footprint).
3. **Then proceed with Phase 5** in two stages:
   - **5a**: top-half recovery bowl SCAD + STL + viewer wiring (mirror of
     the existing bottom-pool half-disc, footprint y ≥ 0, no V-cone).
   - **5b**: self-cleaning UI button + state machine + counter, scripted
     against the `vac_clean_tube` mouth at z = floor + 7 mm.
4. **Phase 6 (gear drive + motor mount)** unblocks once the pool/recovery
   geometry is final, since the gear pinion and motor mount need fixed
   anchor points on the housing wall.
5. Open decision points from project `CLAUDE.md` still **unanswered**:
   bearing choice (Phase 7), viewer deployment target, print material,
   first physical print phase. None are blocking the audit conclusions but
   should be resolved before BOM work.

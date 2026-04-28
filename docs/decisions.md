# Architectural Decisions

## D1 — Disc tilt axis: world-X, not world-Y (Phase 1)

**Date:** 2026-04-27.
**Question:** The plan stated *disc-normal = (sin45°, 0, cos45°)* AND *pickup-zone = (0, 29.7, 29.7)*. These are inconsistent — they describe two different rotation axes.

**Decision:** Honour the pickup-zone coordinate. Tilt the disc with `rotate([45, 0, 0])` (around world X). Disc-normal becomes `(0, -sin45°, cos45°)`.

**Why:** The pickup-zone coordinate is more specific, more useful for downstream geometry (reservoir outlet must drop seeds onto it), and easier to test. The disc-normal phrasing in the spec was a typo (X/Y swap).

**Consequence:** All later phases must follow this convention. The reservoir outlet sits above `(0, 29.7, 29.7)`. The release zone is at `(0, -29.7, -29.7)`.

---

## D2 — Phase-1 open decisions resolved (2026-04-27)

1. **Phase-7 bearing:** edge rollers (default).
2. **Viewer deployment:** local only. `python3 -m http.server -d viewer 8000`.
3. **Print material:** PETG (transparent, sterk, hittebestand).
4. **First physical print:** later than Phase 3.
5. **Working language:** English.

---

## D4 — Reservoir outlet clearance: 17 mm above pickup-top, not 5–8 mm (Phase 2)

**Date:** 2026-04-27.
**Question:** The plan called for the reservoir outlet to sit 5–8 mm above the pickup-zone, with a Ø12 outlet and ≥5 mm clearance from the disc everywhere.

**Geometric finding:** With the disc tilted 45° around X, the disc top surface follows the plane `z = y + 2.828`. A horizontal Ø12 outlet centered above the pickup-top point `(0, 28.28, 31.11)` has its outer wall (Ø16 with 2 mm wall) reaching to `(0, 36.28, z_out)`. For ≥5 mm perpendicular clearance to the disc top plane:

> `cos(45°) · (z_out − 36.28 − 2.828) ≥ 5  ⇒  z_out ≥ 48.1`

i.e. **the outlet must be ≥17 mm above the pickup-top point**. With 5–8 mm clearance, the outer rim clips the rising disc surface.

**Decision:** Set `RESERVOIR_OUTLET_CLEARANCE = 17` mm. Outlet at `(0, 28.284, 48.113)`. Drop distance to disc-top is 17 mm. Validation confirms ≥6.5 mm minimum clearance (`reservoir_disc_clearance` check).

**Consequence / future options:** to recover the original 5–8 mm range, either (a) shrink the outlet (Ø6–8), (b) tilt the outlet plane parallel to the disc (seeds would no longer fall vertically), or (c) shape the outlet asymmetrically — bias the +Y rim inward. Defer until physical testing shows whether 17 mm drop causes seed bouncing.

---

## D6 — V5 architecture: vacuum pickup from bottom seed-pool (Phase 2 rewrite)

**Date:** 2026-04-27.
**Question:** D5 placed pickup and release symmetrically near the disc top (V4-drawing interpretation). Hendrik then directed a complete architecture switch: V4 (gravity-fed top reservoir) → V5 (vacuum pickup from a bottom seed-pool, Monosem/MaterMacc/vSet pattern).

**Decision:** Adopt V5. Concretely:

- Pickup at **θ=270°** (disc bottom): world (0, -29.7, -29.7). Disc dips into an open seed pool.
- Release at **θ=90°** (disc top): world (0, +29.7, +29.7), directly above the central drop hole.
- Seed travels **180° along the disc rim** with θ decreasing (Option 1 — front face rises into the release zone).
- Reservoir is no longer a top funnel. It is a **60 × 40 × 20 mm open bowl** centred at (0, -30, -35), with a V-trough bottom (6 mm strip) so seeds gather along the disc-rim dip line.
- Vacuum behind the disc draws seeds against the disc FRONT face (the face whose normal has +Y component).

**Why V5 over V4:**
- **Singulation precision.** Vacuum self-limits to one seed per hole (extra seeds fall back into the pool). Gravity-fed top reservoirs over-feed and need an `afstrijker` to scrape excess.
- **Zero kinetic energy at pickup.** Seeds in a pool are stationary; vacuum captures them at v=0. Top-reservoir seeds arrive at the disc with several mm/s of velocity from the drop, increasing bounce risk.
- **Natural reservoir emptying.** Vacuum draws from the lowest point — pool empties uniformly.
- **Lower CG.** Reservoir mass is now low in the housing.
- This matches the dominant precision-seeder pattern (Monosem MS, MaterMacc MS-300, Precision Planting vSet, John Deere ExactEmerge).

**Geometric consequences (open issues, see build_log):**

1. *Disc TEETH dip below pool floor.* Tooth tips at α=270° sit at world z=-48.09; pool floor at z=-45 → 3 mm interference. SCAD model digitally seals the floor by clipping the envelope subtraction; physical hardware would need either a lower floor (z=-50) or no teeth at this stage. Validation reports `disc_above_floor: gap=-2.22 mm` until Hendrik picks one.
2. *Side-wall slots leak.* The disc passes through slots in X=±30 walls. Real Monosem-style sealing brushes are deferred to Phase 3+.
3. *Released-seed miss confirmed.* At release, tangential velocity is +22 mm/s in +X (5 RPM); free-falling seed lands on the disc back face. Phase 3 deflector is mandatory.

**Consequence for prior decisions:**
- D4 (outlet clearance trade-off) is now historical — there is no outlet.
- D5 (pickup θ=110°, release θ=70°) is superseded by this decision.

**Files retired:** `scad/v4_2_reservoir.scad` (deleted from tree, kept in git history).
**Files added:** `scad/v5_2_seed_pool.scad`, `stl/v5_2/{disc,seed_pool}.stl`, `renders/v5_2/`.

---

## D5 — Pickup at θ=110°, release at θ=70° (Phase 2 fix)

> *Superseded by D6.* The θ=110°/70° interpretation honoured a possible reading of the V4 drawing but was wrong about the architecture entirely (top reservoir vs bottom pool). Kept here for traceability.

**Date:** 2026-04-27.
**Question:** The original Phase-2 build placed the release at the disc's LOWEST point (0, −29.7, −29.7) — the geometric "180° opposite" of the pickup. The V4 concept drawing's "Vooraanzicht schijf" panel shows pickup AND release both near the TOP of the disc, symmetric around the Y axis. Seeds travel the LONG way around the rim (~320°), not the short way through the bottom.

**Decision:** Pickup at θ=110°, release at θ=70° on the pickup-hole circle (R=42), where θ is the disc-local angle and world coords come from `(R·cosθ, R·sinθ·cos45°, R·sinθ·sin45°)`. Both markers at world Z = 27.907 mm, X-separated by 28.73 mm. Seed path is CCW: 110° → 200° → 290° → 360° → 70° = 320° of rotation.

**Reservoir outlet** now shifts to `(−14.365, 27.907, 35.000)` — directly above the new pickup. Vertical clearance dropped from 17 mm to 7.1 mm.

**Geometric consequence — clearance regression:** with the outlet centered at y=27.907 and the Ø16 outer wall reaching to y=35.907, the disc-top plane z = y + 2.828 sits at z=38.735 at that rim. The outlet bottom is at z=35, so the +Y outer rim is BELOW the disc top by 3.7 mm vertical (≈2.6 mm perpendicular). Validation confirms: `min clearance = 0.10 mm` at (−19.7, 32.3, 35.0). The outlet wall and the disc body interfere.

To restore ≥5 mm perpendicular clearance with the outlet centered above PICKUP_POS, the +Y outer rim point must satisfy `z − y ≥ 9.9`. Three options:

1. **Raise outlet to z ≈ 45.8 mm** (clearance back to ~17.9 mm above pickup). Geometrically clean, but the seed drop-distance grows again — risk of bouncing.
2. **Shrink outlet to Ø6 inner / no outer flange, wall=1**: +Y rim at y = 27.907 + 4 = 31.907 → z − y = 35 − 31.907 = 3.1, still below the 9.9 threshold. So shrinking alone doesn't fix it; would need to also raise z slightly.
3. **Tilt the outlet plane parallel to the disc** (rotate outlet ≈45° around X so the bottom rim follows the disc surface). Seeds drop along the disc normal, not vertically — physics still works because the disc surface is the relevant plane.
4. **Asymmetric outlet** — bias the +Y rim inward (D-shaped or oval bottom). Cleanest visually, but harder to print.

**Pending Hendrik's call.** Until then, the build keeps the user's specified marker/outlet positions and the validation script reports the clearance violation honestly rather than masking it.

**Drawing-derived insight:** Front face of the disc rotates UP at the release side (Hendrik's "Schijf draait aan voorzijde omhoog"). With +ω around `DISC_AXIS = (0, −sin45°, cos45°)`, the velocity at release (+14.4, 27.9, 27.9) is in the (0, +y, +z) direction → front face rises into the release zone. Current viewer rotation direction is correct; no reversal needed.

---

## D7 — Geleider throat below disc-body slab; slot subtraction for clean rotation (Phase 3)

**Date:** 2026-04-27.
**Question:** Spec put the geleider throat at world (0, 0, 5) and catch-mouth opening at z=20. A straight lofted hull from a 44×24 mm rectangular mouth at z=22, y=30 to a Ø34 circular ring at z=6, y=0 unavoidably passes through the disc-body slab `|z − y| ≤ 2.83 mm` at intermediate z. The disc top face at θ=90° sits at z = y + 2.83; the loft's centerline at z=15 sits at y≈16, where disc body is present at |x|≥13, and the loft has X-extent ±20. Result: 249/5000 sampled geleider surface points landed within 1 mm of disc — direct interference.

**Decision:**
1. **Lower the throat to z = −6** (was 5). With y=0 at the throat, |z−y|=6 > 2.83 → the throat sits cleanly below the disc-body slab. The path centerline now satisfies `0.9·y − 6 < y − 2.83` ⇔ `y > −31.7` — true everywhere on the path.
2. **Subtract the disc envelope (with 3 mm clearance) from the geleider** — same trick used on the seed-pool side walls. Carves a slot through the geleider where the disc passes; rotation is unobstructed; clearance ≥3 mm validated by trimesh proximity sampling.
3. **Drop-tube top moves with throat** — DROP_TUBE_Z_TOP = −6.

**Why not narrower mouth or higher mouth instead:**
- Narrower mouth (X-shrink): the mouth catches a +X-velocity seed at release. With 5 RPM tangential speed 22 mm/s and ~0.04 s fall time, the seed displaces ~1 mm in +X — Ø10 mouth is enough kinematically. But disc body width across the loft is ~|x| ∈ [13, 60], and even a narrow mouth's *loft surface* (sides flaring from throat to mouth) crosses the disc body unless the throat is below the body slab.
- Higher mouth: would put the mouth opening at z > 27 to clear the disc body at y=30 (where body face sits at z=27.17). Seed drop distance and bounce risk grow.

**Consequence:**
- Slot subtraction means the geleider leaks seeds where the disc passes through. Real hardware needs Monosem-style sealing brushes around the disc rim — same as the seed-pool side-wall slots from D6. Deferred to a later phase, flagged as a design constraint.
- Drop-tube starts higher up (z=−6 instead of z=5), making it 11 mm longer than the spec assumed. Still fits comfortably through the disc Ø50 central hole (10 mm radial slop).

**Files changed:** `scad/lib/parameters.scad` (GELEIDER_THROAT_Z, DROP_TUBE_Z_TOP), `scad/v5_3_barriere_geleider.scad` (added `disc_envelope_for_geleider()` subtraction), `validation/geometry_check.py`.

---

## D8 — V5 FLIP: seed-attachment side swapped to operator-visible (post-Phase-4)

**Date:** 2026-04-27.
**Question:** Phase 4 closed with the vacuum chamber on the operator-visible
side of the disc and seeds attaching on the operator-far side. Hendrik
inverted this: chamber must hide *behind* the disc, seeds and afstrijkers
must sit on the *visible* face.

**Decision:** Post-flip frame — `FRONT_NORMAL = (0, −sin45°, +cos45°)`,
i.e. seeds attach in the `disc_plane_eq > 0` half-space (camera at
+X, −Y, +Z is in eq>0). Chamber centroid post-flip is `(−26.67, +6.67,
−6.67)`, eq = −9.43 (opposite side, hidden).

**Why:** Operator must see the seeds and the singulator blades during
calibration; the rotating-seal interface against the disc back face is
internal and doesn't need to be visible. Same orientation as physical
Monosem/MaterMacc machines.

**Implementation:** SCAD-side `mirror([0,0,1])` added to `vacuum_chamber()`
before the tilt rotation; both afstrijker SCAD modules had their pre-tilt
mirror *removed* so they stay on the seed-attachment face. Anchor-based
verification in `viewer.js` (centroid-vs-expected with 1.5–2.0 mm tol)
gates every STL load and prints PASS/FAIL to console.

**Files changed:** `scad/v5_3_barriere_geleider.scad`,
`scad/v5_4_vacuum_chamber.scad`, `viewer/viewer.js` (anchor block).

---

## D9 — Vacuum-respecting release glide instead of free-fall + geleider catch

**Date:** 2026-04-27.
**Question:** At natural release (θ=90°) the seed has tangential velocity
~22 mm/s in +X (5 RPM). A free-fall trajectory with gravity passes through
the disc-body slab `|z−y| ≤ 2.83 mm` on its way down to the geleider
catch-mouth — the seed visibly clips through the rotating disc.

**Decision:** Two-stage glide replaces free-fall when vacuum is on:
- **Stage 1** (0.45 s): seed slides along the disc-front face from rim
  point at θ=90° inward to a midpoint above the central axis (R=0,
  Z=+3 in disc-local), staying 3 mm above the disc face throughout.
- **Stage 2** (0.30 s): vertical drop through the central Ø50 hole into
  the geleider throat at z=−5.

The original free-fall + geleider-catch path is preserved as a fallback
for vacuum-loss mid-cycle (the "missed" counter still increments when
free-falling seeds escape the catch-mouth).

**Why:** Physically realistic — vacuum still holds the seed against the
disc as it crosses θ=90°; gravity wins only after the seed clears the
rim. The two-phase trajectory respects this without simulating full
fluid dynamics. Visually no clipping through the disc.

**Files changed:** `viewer/viewer.js` (`glideToThroat()`,
`updateGliding()` two-stage branch).

---

## D10 — Half-disc bottom pool footprint (v5.5.0–v5.5.2)

**Date:** 2026-04-27.
**Question:** Original V5 pool was a 60 × 40 × 20 mm rectangular box at
floor z=−45. Several issues stacked up: tooth tips at θ=270° dipped
3 mm below floor (D6); side walls were vertical 4-mm slits where the
disc passed through (leak risk); fixed front/back orientation didn't
catch seeds detaching mid-arc.

**Decision (three iterations):**
1. **v5.5.0** — relocated vac-cleanup tube from front-mount (45° elev)
   to top-mount (80° elev = 10° off vertical), widened feeder bore from
   OD16/ID12 to OD18/ID14 (reduces soybean bridging risk).
2. **v5.5.1** — V-cone bottom in both X and Y (4 × 4 mm floor patch),
   floor lowered from −37 to −50 mm. Resolves the long-standing
   `disc_above_floor` validation failure: with floor at −50 the disc
   teeth (lowest at z ≈ −48.1) no longer reach the floor at all.
3. **v5.5.2** — rectangular footprint replaced with a half-disc body
   (R_OUTER=55, opening at y=0, footprint y ≤ 0). Wraps the disc
   bottom 180° in plan view → catches seeds detaching anywhere in
   the bottom-arc XY-projection.

**Trade-off accepted:** half-disc + single-point V-cone gives 28° side-
slope (toward ±X), below the ≥35° self-feeding spec. Soybean rest angle
is ~25–30°, so it works but is tight; mitigations deferred (curved
trough following disc rim, rim-following internal rib, or tighter
R_OUTER ≈ 40 for ~38° slopes at the cost of catch area).

**Why this footprint:** R_OUTER=55 was sized to keep the existing tube
anchors INSIDE the half-disc body (feeder anchor radius 52.2, vac
anchor radius 42, both < 55). Phase-5 recovery bowl mirrors this
R_OUTER on the y ≥ 0 side for visual symmetry.

**Files changed:** `scad/lib/parameters.scad` (SEED_POOL_R_OUTER,
floor=−50, depth=33, feeder/vac tube params),
`scad/v5_2_seed_pool.scad` (half-cylinder body, V-cone hull cavity,
vac tube tilted 80° top-mount), `validation/geometry_check.py`
(`y_back_edge` replaces `y_back_face`).

---

## D3 — Three.js vendoring strategy (Phase 1)

**Decision:** Vendor only the three files we use (`three.module.js`, `OrbitControls.js`, `STLLoader.js`) into `viewer/vendor/`, total 1.3 MB. Resolve via importmap.

**Why:** Hendrik wants fully local serving. `npm install` of the full package pulls in 32 MB of unused source/examples. Vendoring three files keeps the repo small and makes `python3 -m http.server -d viewer` work without any other tooling.

**Consequence:** When updating three.js, copy the same three files from `node_modules/three` (regenerated via `npm install three` in `viewer/`).

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

## D5 — Pickup at θ=110°, release at θ=70° (Phase 2 fix)

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

## D3 — Three.js vendoring strategy (Phase 1)

**Decision:** Vendor only the three files we use (`three.module.js`, `OrbitControls.js`, `STLLoader.js`) into `viewer/vendor/`, total 1.3 MB. Resolve via importmap.

**Why:** Hendrik wants fully local serving. `npm install` of the full package pulls in 32 MB of unused source/examples. Vendoring three files keeps the repo small and makes `python3 -m http.server -d viewer` work without any other tooling.

**Consequence:** When updating three.js, copy the same three files from `node_modules/three` (regenerated via `npm install three` in `viewer/`).

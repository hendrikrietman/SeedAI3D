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

## D3 — Three.js vendoring strategy (Phase 1)

**Decision:** Vendor only the three files we use (`three.module.js`, `OrbitControls.js`, `STLLoader.js`) into `viewer/vendor/`, total 1.3 MB. Resolve via importmap.

**Why:** Hendrik wants fully local serving. `npm install` of the full package pulls in 32 MB of unused source/examples. Vendoring three files keeps the repo small and makes `python3 -m http.server -d viewer` work without any other tooling.

**Consequence:** When updating three.js, copy the same three files from `node_modules/three` (regenerated via `npm install three` in `viewer/`).

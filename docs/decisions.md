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

## D3 — Three.js vendoring strategy (Phase 1)

**Decision:** Vendor only the three files we use (`three.module.js`, `OrbitControls.js`, `STLLoader.js`) into `viewer/vendor/`, total 1.3 MB. Resolve via importmap.

**Why:** Hendrik wants fully local serving. `npm install` of the full package pulls in 32 MB of unused source/examples. Vendoring three files keeps the repo small and makes `python3 -m http.server -d viewer` work without any other tooling.

**Consequence:** When updating three.js, copy the same three files from `node_modules/three` (regenerated via `npm install three` in `viewer/`).

# PROTISEM V4 — Project Memory

**Goal:** 45° slanted vacuum seeding disc with pointed reservoir, top pickup, diagonal top release, fall through central hole. 10 sequential CAD phases, each ending in a working browser-side three.js viewer.

**Operator:** Hendrik Rietman, PROTISEM Breeding B.V.
**Workdir:** `~/workspace/protisem-v4/`

---

## Non-negotiable dimensions

- Disc OD 120 mm (132 mm with tooth rim), thickness 4 mm
- Central hole 50 mm Ø
- 40 pickup holes on R=42 mm, 2.5 mm Ø, **perpendicular to disc plane** (not world-vertical — common bug)
- 60 teeth, modulus 1.5
- Disc tilted 45° from horizontal
- Reservoir ~200 seeds (~50 ml), wall slope ≥35°
- Housing 180×180×60 mm, 3 mm PETG transparent

## Reference frame

- World: X=left/right, Y=front/back, Z=up
- Disc centre at origin after rotation
- Disc normal = (sin45°, 0, cos45°) ≈ (0.707, 0, 0.707), points front-up
- Pickup zone = highest point on R=42: (0, 29.7, 29.7)
- Release zone = 180° around disc rim from pickup

## Working discipline

- Fully parametric: every dimension lives in `scad/lib/parameters.scad`, no hardcoding elsewhere.
- Cross-section views built into every SCAD file by default.
- Each phase produces visibly working output. Don't proceed until the HTML viewer is verified.
- After each successful phase: `git commit -m "Phase X: …"` and tag `v4.X`.

## Per-phase loop

1. Read `scad/lib/parameters.scad` for current values.
2. Edit/add SCAD source.
3. Run `validation/geometry_check.py`.
4. Export STL + PNG cross-sections.
5. Update `viewer/index.html`, open in browser, visually verify.
6. Append 1-2 lines to `docs/build_log.md`.
7. Commit + tag.

## The 10 phases

1. Parametric disc + viewer bootstrap
2. Spits reservoir with diagonal outflow
3. Afstrijker barriere + guide funnel
4. Housing with sector vacuum chamber
5. Drop tube through central hole
6. Gear drive + motor mount (BLDC NEMA17, 20T pinion, 60T disc, 3:1)
7. Edge-roller bearings (3× 608ZZ) — **pending Hendrik confirmation**
8. Sensors + vacuum source interface
9. Multi-element 4-row assembly
10. Final assembly, BOM, validation protocol, production viewer

## Viewer stack

- three.js r150+ (npm or CDN)
- STLLoader + OrbitControls
- Auto-rotation around disc 45° axis (not world Y)
- Cross-section toggle (plane at Y=0)
- RPM slider (0–30)
- Background light grey, disc PETG-blue

## Open decision points (answer before Phase 1)

1. Bearing choice (Phase 7): edge rollers / eccentric shaft / hollow drop-tube shaft? Default = edge rollers.
2. Viewer deployment: subdomain on breed.protisem.com, or local `python -m http.server`?
3. Print material: PETG or PLA?
4. First physical print: after which phase? Recommendation = after Phase 3.

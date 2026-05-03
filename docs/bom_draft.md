# SeedAI3D — BOM stub (per single sowing element)

> **Status:** stub — full BOM is deferred until after first physical print
> per Phase F of `docs/prompt_plan.md`. This file collects sourced parts
> as they accumulate during digital design (currently D14 hardware only).

## Air-flow regulation hardware (D14)

Required to keep the sowing element inside the soybean operating window
of **vacuum −3 to −8 kPa, blow +0.5 to +2 kPa**. Without these the
shop-vac sources are too aggressive and the disc face-loads against the
seal (vacuum side) or seeds get launched (blow side).

| Qty | Part | Spec | Source (example) | ~€ |
|----:|------|------|------------------|----:|
| 1 | Vacuum-line manual needle valve | M5 / G⅛ thread, 0–10 kPa adjustment | RS 570-356 or McMaster 7768K81 | 8 |
| 1 | Blow-line manual needle valve | Same spec | (as above) | 8 |
| 1 | T-fitting | Ø19 silicone hose, 3-way | RS 219-9270 or local | 4 |
| 1 | Push-in fitting, vacuum nipple | Ø12 OD / Ø8 ID, M5 thread | Festo QSM-M5-12 or generic | 5 |
| 1 | Push-in fitting, blow nipple | Ø10 OD / Ø6 ID, M5 thread | Festo QSM-M5-10 or generic | 4 |
| ~2 m | Silicone vacuum hose | Ø19 OD / Ø12 ID, food-grade | RS 388-2832 | 6 |
| 1 | NBR O-ring cord, Ø2.5 mm | Length ≈ 2π × (R_OUTER + R_INNER) / 2 + slack ≈ 270 mm | RS 280-786 (cut to length) | 3 |
| 1 | Wet/dry shop-vac (vacuum source) | ≥30 L/min free-air, hose adapter Ø19 | Operator-supplied | (shared) |

Subtotal: ~**€38** in regulation hardware per element (excluding shop-vac
itself, which is shared across elements).

## Notes on sourcing

- The manual needle valves are the operator's primary tuning knob; they
  must be in-line and easily reachable from the operator position. A
  digital pressure gauge tee'd into each line is a recommended next
  upgrade (deferred to a post-print phase).
- The push-in fittings replace the printed nipple bodies — see D14 §4
  for why the blow nipple body is not modelled in the printed mal-plate
  STL. Both bores are sized for M5-threaded fittings with a 1 mm tap-tap
  allowance; the operator taps the bore after print.
- O-ring cord is sold by the metre and cut to length on installation.
  Two short pieces (one per sub-sector) totalling ~270 mm with ~30 mm
  slack each.

## Future BOM additions (deferred)

These items belong in the BOM but are blocked on first physical print
data per Phase F:

- Optical seed counter in drop tube (sensor type + mount) — Phase 6 of
  the friend's review.
- M3 brass heat-set inserts for the lid retention clips (4 ×).
- M3 × 10 mm screws for the lid (4 ×).
- NEMA17 stepper motor + driver + 12 V supply.
- RTK GPS receiver (optional, Phase 7+).
- Crop-specific disc inserts (D14-soybean baseline; edamame / snapbean /
  cowpea variants once benchtop data sets the hole geometry).

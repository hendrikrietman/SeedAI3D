# SeedAI3D

> AI-augmented, 3D-printable, breeder-first vacuum precision sowing element.

## What is this

A precision sowing element designed for plant breeders, not for industrial agriculture. Open-source, parametric, 3D-printable.

Commercial precision seeders (Monosem, MaterMacc, Stanhay) cost €5,000-25,000 and are built for thousand-hectare farming. They don't serve the plant breeding community well: small plots, frequent line changes, zero contamination tolerance, need for line-tracking.

SeedAI3D fills that gap. Estimated cost per element: €50-150 (printed parts + electronics + small parts).

## Distinguishing features

- **Vacuum pickup from seed-pool** — Earthway/MaterMacc-style
- **Zero-loss recovery bowl** surrounding disc seed-path — fallen seeds return to pool
- **Dual-tube self-cleaning** between lines (feeder + vacuum-cleaner-port)
- **Parametric design** adaptable to soybean, edamame, lima, snapbean
- **Optional RTK GPS integration** for plot-tracking and adaptive sowing speed

## Status

Prototype design phase. CAD architecture complete. First 3D-print pending.

This repository contains:
- Parametric OpenSCAD designs
- Three.js interactive viewer (real-time animated cycle visualization)
- Build documentation
- Design rationale and architecture decisions

## Architecture phases

- **Phase 1:** 132mm tilted disc with 60 teeth, 40 pickup-holes (Ø4mm)
- **Phase 2:** Bottom seed-pool architecture
- **Phase 3:** Singulator deflectors + guide funnel + 6-state seed lifecycle
- **Phase 4:** Vacuum chamber with O-ring sealing
- **Phase 6:** Integrated mal-plate (motor + drive + chamber in one)
- **Phase 7:** Transparent housing with integrated tubes (in progress)

## License

CC-BY-SA 4.0 — share-alike, attribution required.

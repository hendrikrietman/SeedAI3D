# SeedAI3D — Prompt Plan (Hetzner / Claude Code)

**Purpose.** A controlled, phase-based execution plan for Claude Code running
on the SeedAI3D Hetzner box. Each phase is a small, atomic unit of work that
produces a branch, a PR, and updated docs. Main is never touched directly.

**Audience.** The human operator (Hendrik, or a delegated contributor) pastes
the per-phase prompt into a Claude Code session running in
`~/SeedAI3D` on the Hetzner box. Claude Code executes one phase, ends the
session, the human reviews the PR on GitHub, merges or requests changes,
and only then is the next phase started.

**Status as of 2026-05-03.**

- Current main branch is at v5.8.5 (single-sector chamber, Ø12/Ø8 nipple,
  soybean-only disc).
- A working branch `v6_2028_ready` exists locally with the v6.0 dual-sector +
  crop-swappable revision (D14–D18). This branch has NOT been merged to main
  and is not part of this prompt plan — it is a pre-existing artifact that
  will either be merged separately by Hendrik or rebased into Phase 5 below.
- The phases here are derived from the external review by Hendrik's friend
  (12-phase roadmap) but **deliberately scoped down** to the four highest-
  leverage items (1, 2, 4, 5) plus a workflow-setup phase 0 and a
  print-prep phase F. Phases 3, 6–12 from the original review are deferred
  until after the first physical print produces real benchtop data.

---

## Universal startprompt (paste at the start of every Claude Code session)

```
You are working on the GitHub repository SeedAI3D, checked out at ~/SeedAI3D
on a Hetzner Linux box. The default shell is bash. Network egress is
restricted by the Hetzner firewall — only api.github.com, the OpenSCAD
package archive, and pypi are reachable.

Hard rules. Do not violate these even if asked:
- Never push directly to `main`.
- Never force-push.
- Never delete branches that have associated open PRs.
- Never edit generated STL files by hand. STL changes come from re-rendering
  SCAD sources.
- Never modify `scad/lib/parameters.scad` and the matching SCAD module in
  separate phases. They move together.
- Never touch the local-only Three.js viewer's vendored library files
  (`viewer/three.min.js`, etc.).
- Never remove existing viewer toggles or seed-lifecycle logic unless the
  current phase explicitly replaces them.
- Soybean is the default crop profile. Phase work that adds other crops must
  not break the soybean default.

Workflow rules:
- Create a new branch from `main` for the current phase. Branch name is
  given in the per-phase prompt.
- Read these files before any code change:
    README.md
    docs/decisions.md
    docs/build_log.md
    docs/audit_report_v5.md
    scad/lib/parameters.scad
    viewer/index.html
    viewer/viewer.js
    validation/geometry_check.py
- Make changes in the order: docs → SCAD parameters → SCAD modules →
  viewer → validation → re-run validation → update build_log → update
  decisions if architectural.
- Run `python3 validation/geometry_check.py` before declaring the phase
  done. Report the PASS/FAIL count.
- If validation fails, do not commit. Diagnose, fix, re-run.
- After all changes pass, commit with a message that begins
  `[phase-N]` where N is the phase number from this plan.
- End the session with a PR summary in this exact format:

  ## PR Summary

  **Branch:** <branch-name>
  **Phase:** <phase-number-and-title>

  **Files changed:**
  - <list>

  **Validation:** <PASS_count>/<total> PASS, <FAIL_count> FAIL
  (FAIL details if any)

  **Docs updated:**
  - docs/build_log.md: <one-line summary>
  - docs/decisions.md: <new decision ID, or "no change">

  **Remaining risks / TODO:**
  - <list, one bullet per risk>

  **Suggested PR title:** <title>
  **Suggested PR body:** <2–4 sentence summary suitable for the GitHub PR>

Do NOT open the PR yourself. The human reviews the branch and opens the PR
manually on github.com.

If at any point you are unsure whether an action is in scope for the current
phase, STOP and write your question to the chat. Do not improvise scope
expansions.
```

---

## Phase 0 — Workflow setup (PR scaffolding, branch protection, AGENTS.md)

**Why first.** The friend's review is correct that the project lacks the
standard branch-per-phase / PR / validation-gate workflow. Establish that
infrastructure before any technical work. This phase is cheap, all
documentation, and unlocks everything below.

**Branch:** `phase-0-workflow-setup`

**Prompt:**

```
[Paste universal startprompt above first]

Implement Phase 0 only. Create branch `phase-0-workflow-setup` from main.

Tasks:

1. Create `.github/PULL_REQUEST_TEMPLATE.md` with sections:
   - Summary (what this PR does in 1–3 sentences)
   - Phase reference (which phase from docs/prompt_plan.md)
   - Files changed (list)
   - Validation result (PASS/FAIL count, copy from validation output)
   - Docs updated (build_log, decisions if applicable)
   - Reviewer checklist (boxes for: validation passes, soybean default
     intact, no STL hand-edits, no main-pushed commits, viewer
     toggles preserved)

2. Create `AGENTS.md` at the repo root. Contents:
   - Brief project overview (2 paragraphs, derive from README.md)
   - Pointer to docs/prompt_plan.md as the authoritative phase plan
   - Pointer to docs/decisions.md as the architectural decision record
   - Pointer to docs/build_log.md as the chronological log
   - The hard rules and workflow rules from the universal startprompt
     above, copied verbatim
   - A note that AGENTS.md and CLAUDE.md should be kept in sync; if both
     exist, treat them as identical content with different filenames for
     OpenAI Codex vs Anthropic Claude Code respectively.

3. If `CLAUDE.md` exists at the repo root and differs from AGENTS.md,
   reconcile so that both files contain identical content. The shared
   content is whichever is more current.

4. Add a section to `README.md` titled "Contributing" that points to
   docs/prompt_plan.md and AGENTS.md, and describes the branch-per-phase
   workflow in 4–6 lines.

5. Update `docs/build_log.md` with a Phase 0 entry: "Workflow scaffolding
   added: PR template, AGENTS.md, contributing section in README."

Do NOT change any SCAD, viewer, validation, or STL files in this phase.

Run `python3 validation/geometry_check.py` to confirm the validation
harness still works (no geometry change expected — confirms no PASS/FAIL
regression).

End with PR summary per the universal startprompt format.
```

**Acceptance criteria.**
- `.github/PULL_REQUEST_TEMPLATE.md` exists.
- `AGENTS.md` exists at repo root, content matches CLAUDE.md if present.
- README.md has a Contributing section.
- Validation count unchanged from baseline (48/48 PASS or whatever main is at).
- `docs/build_log.md` has a Phase 0 entry.

**Estimated time.** 1–2 hours including Claude Code session and human review.

---

## Phase 1 — Physical prototype roadmap (documentation only)

**Why.** Articulates the breeder-specific requirements (zero seed carryover
between genotype lines, tool-less cleaning, removable seed-contact parts,
optical seed counter, plot logging) as a first-class document. Forces
explicit thinking about gaps between the current digital model and a
field-ready instrument. Pure docs, no code, low risk.

**Branch:** `phase-1-physical-prototype-roadmap`

**Prompt:**

```
[Paste universal startprompt first]

Implement Phase 1 only. Create branch `phase-1-physical-prototype-roadmap`
from main.

Task: Create `docs/physical_prototype_roadmap.md`.

Goal: Document the transition from the current SeedAI3D digital/CAD
prototype to a field-ready research-plot sowing element.

Required sections (in this order):

1. Current state — what v5.8.5 (or current main) is and is not. Reference
   the audit report. State explicitly that no physical print exists yet.

2. Physical prototype gaps — bulleted, each gap stated as a missing
   capability in the current design. Required gaps to cover:
   - zero seed carryover between genotype lines (the breeder-specific
     requirement that distinguishes this from a commodity-farming seeder)
   - tool-less cleaning between lines
   - removable seed-contact parts
   - rim brush seals at all disc pass-through slots
   - explicit O-ring/vacuum seal hardware (currently parameterized but not
     documented as BOM)
   - optical seed counter in the drop tube
   - plot logging / RTK interface
   - crop-specific removable discs (partially addressed in v6.0 D14)
   - first physical print validation (no benchtop data exists)

3. Proposed phase sequence — list this prompt plan's phases 2, 4, 5, F
   in order with a one-sentence summary of each. Note that phases 3, 6–12
   from the friend's review are deferred until after first physical print.

4. Acceptance criteria per phase — copy from each phase's "acceptance
   criteria" section in this prompt plan.

5. Open decisions for Hendrik — questions that the design cannot answer
   without empirical data. Examples: vacuum pump spec, sensor type
   (photodiode vs capacitive), brush material (PETG bristle, TPU lip,
   horsehair), motor controller. State them as questions, not
   prescriptions.

6. Risks before first field test — failure modes the design has not yet
   defended against. Include at minimum: seed damage by disc edges,
   carryover via static cling on PETG, vacuum loss through print-layer
   porosity, motor torque under load, drop-tube clogging in dusty seed.

Do NOT change SCAD, STL, viewer, or validation code in this phase.

Update docs/build_log.md with a one-line Phase 1 entry.

End with PR summary.
```

**Acceptance criteria.**
- `docs/physical_prototype_roadmap.md` exists with all six required sections.
- No code changes. Validation count unchanged.
- `docs/build_log.md` has a Phase 1 entry.

**Estimated time.** 2–4 hours including review.

---

## Phase 2 — Architectural decision: physical research prototype

**Why.** Locks the breeder-first / research-plot positioning into the
decision record (D-numbered). Makes "no carryover between lines" an
architectural commitment, not a preference. Separates digital-acceptable
from hardware-required design choices.

**Branch:** `phase-2-decision-physical-research-prototype`

**Prompt:**

```
[Paste universal startprompt first]

Implement Phase 2 only. Create branch
`phase-2-decision-physical-research-prototype` from main.

Task: Add a new entry to `docs/decisions.md`. Use the next sequential
D-number (currently D18 is the highest in the v6 working branch — use D19
unless that is already taken on main, in which case use the next free).

Decision title: "Physical prototype architecture for research plots"

Decision must state:

1. SeedAI3D is treated as a modular single-row metering cartridge. The
   row-unit, frame, opener, depth control, and closing wheel are out of
   scope for this project — those are integration concerns handled by the
   host platform (a 2WT seeder, a plot-drill toolbar, or a manual cart).

2. Line-change cleaning is a primary design requirement, not a polish
   item. Every seed-contact part must be either:
   (a) removable in under 60 seconds without tools, OR
   (b) clearable by an air-blow / vacuum-cleaning cycle in under 60 seconds.

3. Open disc-rim slots are acceptable in the digital viewer (they aid
   visualization) but UNACCEPTABLE in physical hardware. Every location
   where the rotating disc passes through a static seed-contact boundary
   must have an explicit seal in the physical model.

4. Rim-following brush seals OR TPU lips are required at all such
   pass-through slots. Choice of brush vs TPU is per-slot and is made in
   Phase 4. The seal MUST be parameterized in scad/lib/parameters.scad.

5. The vacuum chamber seal must be modeled explicitly in SCAD geometry,
   visible in the viewer (toggle), and listed in the BOM as a discrete
   component (cord, groove, compression spec). This is the work of Phase 5.

6. The drop tube must include an optical seed counter for empirical
   validation of singulation. Without this, every singulation claim is
   unfalsifiable. Sensor design is deferred to a post-print phase.

7. The viewer must support a research-plot workflow as a first-class
   mode (not just a demo): fill line → sow plot → count seed → end plot
   → clean → next genotype. Implementation is deferred to a post-print
   phase but the requirement is locked here.

8. Soybean remains the default first crop. Edamame, snapbean, lima, and
   cowpea are parametric variants. The default must never break.

For each numbered point, include 1–3 sentences of rationale.

Cross-reference to D11 (integrated mal-plate), D13 (visual-vs-physical
overlap), D14 (crop-swappable disc) where relevant.

Do NOT change code or geometry.

Update docs/build_log.md with a one-line Phase 2 entry.

End with PR summary.
```

**Acceptance criteria.**
- `docs/decisions.md` has a new entry (D19 or next sequential).
- The entry contains all 8 numbered statements with rationale.
- Cross-references to prior decisions are explicit.
- No code changes. Validation count unchanged.
- `docs/build_log.md` has a Phase 2 entry.

**Estimated time.** 2–4 hours including review.

---

## Phase 4 — Rim brush seals at all disc slots

(Phase 3 from the friend's review — mal-plate pool access window — is
**deferred** to after first physical print. The current visual overlap
documented in D13 is acceptable until empirical print data informs the
correct fix.)

**Why.** The most important technical gap surfaced by the friend's review.
Brush/TPU seals at every disc pass-through slot is a real engineering
improvement that fixes the carryover problem at its geometric root.

**Branch:** `phase-4-rim-brush-seals`

**Prompt:**

```
[Paste universal startprompt first]

Implement Phase 4 only. Create branch `phase-4-rim-brush-seals` from main.

Task: Add explicit rim-following brush seals at every location where the
rotating disc passes through a static seed-contact boundary.

Slot inventory (audit current main, do not assume):
- bottom seed pool (where disc enters/exits the seed reservoir)
- recovery bowl (where disc passes through bowl wall)
- geleider / catch chute interface
- mal-plate pool access window (if present in current main; v6.0 may add it)

For each slot found, implement seal geometry.

1. Add parameters to scad/lib/parameters.scad in a new section "RIM
   BRUSH SEALS (v6.x — physical prototype requirement, see D19)":
   - RIM_BRUSH_ENABLED (bool, default true)
   - RIM_BRUSH_WIDTH (mm, axial along disc-thickness, default 6)
   - RIM_BRUSH_HEIGHT (mm, radial, default 5)
   - RIM_BRUSH_FLEX_OVERLAP (mm, how much the brush bristles deflect when
     the disc rotates against them, default 0.5)
   - RIM_BRUSH_CLEARANCE (mm, gap between brush root and disc rim before
     deflection, default -0.5 — negative = interference fit)

2. In scad/lib/helpers.scad (or a new scad/lib/seals.scad if cleaner),
   add a reusable module `rim_brush_seal(start_angle, end_angle, radius)`
   that produces simplified brush-seal geometry: a tinted band of
   bristle-like extrusions following the rim at the specified angular
   range and radius. Geometry should be visually distinct (use a separate
   color in the viewer) but does not need to be FDM-printable as-is —
   real brush is a sourced component, the SCAD geometry is a placeholder
   for spatial reservation.

3. Add seal calls at every slot location in the relevant SCAD module
   files. Do not modify the underlying mal-plate, hopper, bowl, or
   geleider geometry — add seals as separate union'd modules.

4. Update viewer/index.html and viewer/viewer.js:
   - add a toggle "Rim brush seals" (default on)
   - load and render seal geometry with a distinct dark/flexible color
   - do not remove any existing toggle

5. Update validation/geometry_check.py:
   - add a check `seals_at_all_disc_slots`: for each known slot
     location (hard-coded list), verify a corresponding seal STL exists
     OR seal geometry is present in the merged assembly STL.
   - add a check `no_rigid_seal_collision`: verify seal geometry does
     not penetrate disc envelope by more than RIM_BRUSH_FLEX_OVERLAP.
   - flexible interference (negative clearance) IS allowed and expected,
     but only up to FLEX_OVERLAP. Hard collision beyond that is FAIL.

6. Re-render any STLs whose source SCAD changed.

7. Update docs/build_log.md with Phase 4 entry summarizing slot count and
   seal coverage.

8. Update docs/decisions.md only if a sub-decision is needed (e.g.
   "use brush vs TPU lip per slot" if you decide differently per slot).
   Otherwise reference D19 from Phase 2.

Acceptance: every disc pass-through slot has an explicit seal
representation, viewer shows seals distinctly, validation reports
seal coverage, no existing viewer function is removed, no soybean
geometry regression.

End with PR summary including validation PASS/FAIL count.
```

**Acceptance criteria.**
- All disc pass-through slots identified in current main have a seal.
- Validation passes (likely 50+/50+ now with the two new checks).
- Viewer renders seals distinctly with a working toggle.
- Existing toggles preserved.
- Build log and decisions updated.

**Estimated time.** 1–2 weeks. This is a real engineering change touching
SCAD, viewer, and validation. Budget for Claude Code iterations and PR review.

**Risks to flag in PR summary.**
- Brush/TPU material choice is unresolved at this phase — see D19, item 4.
  This phase reserves the geometry; Phase F (physical print prep) decides
  the material.
- Validation of "no rigid collision" relies on disc envelope sampling —
  edge cases at the slot transitions may need tolerance tuning.

---

## Phase 5 — Explicit vacuum O-ring and air gap

**Why.** The O-ring groove parameters exist in v6.0 (D15) but the seal is
not documented as a BOM-spec component, not visible in the viewer as a
discrete element, and the air-gap design choice (zero-gap, compressed-O,
or 1.5 mm nominal) is implicit. This phase makes it all explicit.

**Branch:** `phase-5-explicit-vacuum-seal`

**Prompt:**

```
[Paste universal startprompt first]

Implement Phase 5 only. Create branch `phase-5-explicit-vacuum-seal` from
main.

Task: Make the vacuum chamber seal explicit across geometry, viewer,
validation, and BOM documentation.

Note: if the v6_2028_ready branch has been merged before this phase runs,
some of these parameters already exist (ORING_CORD_DIA,
ORING_GROOVE_WIDTH, ORING_GROOVE_DEPTH, ORING_OUTER_R, ORING_INNER_R).
Verify, do not duplicate.

1. Confirm or add parameters in scad/lib/parameters.scad:
   - O_RING_CORD_DIA (mm, NBR cord diameter, default 2.5)
   - O_RING_GROOVE_WIDTH (mm, default 3.2 = 1.27 × cord per ISO-3601)
   - O_RING_GROOVE_DEPTH (mm, default 1.9 = 0.76 × cord per ISO-3601)
   - O_RING_COMPRESSION (mm, calculated: cord - groove_depth - air_gap,
     default 0.1 minimum compression)
   - VACUUM_AIR_GAP (mm, gap between disc-back face and recess-back-wall
     when O-ring is uncompressed, default 0.5)

2. Verify the O-ring groove geometry in the mal-plate SCAD source. If
   already present (v6.0 dual-sector path), confirm. If not, add per the
   path described in D15 / D17.

3. Add an optional O-ring visual geometry: a torus (or pseudo-torus)
   following the groove path, rendered only when a viewer toggle is on.
   This is purely visual; no STL export of the O-ring (it's a sourced
   component).

4. Update viewer:
   - add toggle "Vacuum O-ring seal" (default off — engineers want to
     see the groove without the cord obscuring it)
   - when toggle is on, render the torus geometry in a distinct dark color
   - do not remove any existing toggle

5. Update validation/geometry_check.py:
   - add check `oring_groove_dimensions`: verify groove width / depth
     match parameters within ±0.1 mm tolerance.
   - add check `pickup_holes_in_vacuum_sector`: verify all pickup holes
     at PICKUP_HOLE_RADIUS lie inside the vacuum sector annulus
     (R_IN < 42 < R_OUT).
   - add check `release_zone_outside_vacuum`: verify the release zone
     (currently θ=90° per D11) lies on or just outside the vacuum sector
     boundary, OR that the dual-sector ATM/blow architecture (D15) is
     active, in which case document that.
   - add check `vacuum_air_gap_explicit`: simply verify the
     VACUUM_AIR_GAP parameter is set and report its value (no pass/fail,
     informational only).

6. Update docs/decisions.md:
   - if a decision is required between zero-gap / compressed-O / nominal-
     gap, add a sub-decision (e.g. D20). Default decision: 0.5 mm
     nominal air gap, O-ring under 0.1 mm minimum compression. Rationale:
     allows disc to rotate without grinding into the seal, vacuum seal
     achieved by O-ring face contact. Document the trade-off (slight
     vacuum loss vs zero rotational drag).

7. Add or update a BOM entry in docs (or create docs/bom_draft.md if it
   does not exist — minimal stub, full BOM is a deferred phase) listing:
   - Part: NBR O-ring cord, Ø2.5 mm, length ≈ 2π·(R_OUTER+R_INNER)/2 + slack
   - Source: McMaster, RS Components, or local equivalent
   - Quantity per element: 1 (or 2 if dual-sector)

8. Update docs/build_log.md with Phase 5 entry.

Acceptance: vacuum sealing is no longer implicit; O-ring or groove is
visible in viewer behind a toggle; validation reports seal parameters;
docs explain the seal concept including the air-gap trade-off; BOM stub
exists.

End with PR summary.
```

**Acceptance criteria.**
- All five O-ring parameters present and documented.
- Viewer toggle for O-ring works.
- Four new validation checks added and passing.
- Decision on air-gap explicit in decisions.md.
- BOM stub created or updated.
- Build log entry.

**Estimated time.** 3–7 days.

---

## Phase F — Physical print preparation

**Why.** Bridges from CAD-only to first physical artifact. Without this
phase, all the work above remains theoretical. This phase is what
unblocks every deferred phase (3, 6–12).

**Branch:** `phase-F-print-prep`

**Prompt:**

```
[Paste universal startprompt first]

Implement Phase F only. Create branch `phase-F-print-prep` from main.

Task: Produce print-ready artifacts and a first-print test protocol for a
single soybean element. This phase generates documentation and slicer-
ready files; it does NOT modify SCAD or viewer source.

1. Create `docs/first_print_protocol.md`. Required sections:

   a. Print plan
      - Printer: Prusa MK4S (assumed; document if different)
      - Material: PETG (Prusament or equivalent), one spool ~1 kg
      - Layer height: 0.2 mm general, 0.12 mm for the O-ring groove
        region of the mal-plate
      - Infill: 20% gyroid for plate parts, 30% for the disc, 100% for
        the pinion
      - Supports: tree supports inside the chamber cavity only,
        accessed for removal through the motor cutout
      - Print orientation per part:
        * disc: flat, holes vertical
        * mal-plate: recess-side UP (chamber back wall on the bed)
        * lid: flat
        * dust ring: flat
        * hopper: upside down with brim
        * drop tube: vertical
        * geleider: lofted side down
        * pinion: flat, teeth horizontal
        * afstrijkers: flat
        * vac-tube: vertical

   b. Required STL exports
      - List every part. For each: SCAD source file, expected STL path
        (stl/print_v1/<part>.stl), and the OpenSCAD command line to
        regenerate it.
      - At minimum: disc_soybean.stl, mal_plate.stl, lid.stl,
        dust_ring.stl, hopper.stl, drop_tube.stl, geleider.stl,
        pinion.stl, afstrijker_1.stl, afstrijker_2.stl, vac_tube.stl

   c. Sourced (non-printed) components
      - 1 × NEMA17 stepper motor (per existing parameters)
      - 1 × Ø2.5 mm NBR O-ring cord, length per Phase 5 BOM
      - 4 × M3 brass heat-set inserts (Ruthex RX-M3x4 or equivalent)
      - 4 × M3×10 mm screws
      - 1 × Ø19 silicone vacuum hose, ~2 m
      - 1 × wet/dry shop-vac with hose adapter
      - Cowpea-equivalent or actual soybean seed for benchtop test, ~50 g

   d. Pre-print checklist
      - All STLs watertight (run validation)
      - All STLs fit MK4S build volume 250×210×220 (re-check after any
        v6 merge that changes plate thickness)
      - Heat-set insert stock on hand
      - O-ring on hand
      - Print bed clean, fresh PEI sheet recommended
      - Filament dry (PETG: <10% RH, 4h dry at 65°C if humid)

   e. Print sequence (matches the v6.0 build_log first-print sequence)
      1. Pinion + soybean disc test pair (~3.5 h) — verify 4 mm pickup
         holes resolve cleanly. Hand-mesh pinion against disc-rim teeth.
         Decision gate: if mesh binds, switch to involute pinion before
         continuing.
      2. Mal-plate (~14 h, longest single print) — recess-side up, tree
         supports through motor cutout. Heat-set 4 brass inserts after
         print at ~200 °C with soldering iron.
      3. Lid + dust ring (~4.5 h)
      4. Hopper, drop tube, geleider, afstrijkers, vac tube (~5 h total)
      Total print time: ~30 h.

   f. Benchtop test protocol
      1. Assemble: install soybean disc → seat O-ring → close lid →
         attach VAC nipple to shop-vac → leave ATM nipple open
         (passive vent mode per D15).
      2. Pour ~50 g soybean into hopper.
      3. Spin disc by hand at ~5 RPM for 30 s.
      4. Count: seeds delivered to drop-tube exit / total expected
         (5 RPM × 40 holes × 0.5 min = 100 expected if perfect).
      5. Target: ≥36/min = 90% × 40 holes × 5 RPM ÷ 5 = 36 effective.
         Actual values feed into Phase 6 (sensor) once that exists.
      6. Inspect for: seed damage, double pickups, skips, stuck seeds,
         visible vacuum leaks at the seal.
      7. Record qualitative observations in `docs/first_print_log.md`
         (create as part of test, not this phase).

   g. Decision points after first print
      - If the mal-plate warps or the O-ring groove is unprintable at
        0.12 mm: revisit Phase 5 air-gap design.
      - If singulation rate <70%: revisit hole geometry (D14) and
        vacuum source spec.
      - If carryover after blow-off cycle is >0 seeds: revisit Phase 4
        seal coverage.
      - If pinion-disc mesh fails: switch to involute teeth, deferred
        SCAD work.

2. Create `stl/print_v1/` directory structure (empty, with a README.md
   inside that says "STL exports for first physical print, generated per
   docs/first_print_protocol.md. Regenerate with `make print_v1` or per
   the OpenSCAD commands in the protocol.").

3. Add a `Makefile` (or extend if one exists) with a target `print_v1`
   that runs the OpenSCAD CLI for every required STL. Test the target.

4. Run `python3 validation/geometry_check.py` against the generated
   stl/print_v1/*.stl set. Report the count.

5. Update docs/build_log.md with a Phase F entry summarizing what is now
   ready to print.

Do NOT modify scad/, viewer/, or validation/ source files except to add
the validation invocation against print_v1 STLs (if needed).

End with PR summary, including the print_v1 validation count and a
checklist of every STL file produced.
```

**Acceptance criteria.**
- `docs/first_print_protocol.md` has all 7 sub-sections.
- `Makefile` target `print_v1` works.
- `stl/print_v1/` populated with all required STLs.
- All STLs watertight and fit MK4S volume.
- Validation passes.
- Build log entry.

**Estimated time.** 3–5 days for this phase. Then ~2 days of physical
printing on the MK4S.

---

## Deferred phases (not in this plan)

The following phases from the external review are intentionally NOT in
this plan. They will be reconsidered after Phase F produces real benchtop
data.

| Phase ref | Title                          | Why deferred                                                                  |
|-----------|--------------------------------|-------------------------------------------------------------------------------|
| 3         | Mal-plate pool access window   | D13 documents current state as visual-acceptable. Real fix needs print data. |
| 6         | Optical seed counter           | Sensor mount geometry depends on physical drop-tube behavior. Print first.   |
| 7         | Plot logging mode              | Frontend feature for a viewer demoing a design that has not been validated.  |
| 8         | Research plot mode UI          | Same — UI polish before hardware validation is sequencing wrong.             |
| 9         | Crop profile system expansion  | v6.0 D14 already covers soybean / edamame / snapbean. Lima + cowpea later.   |
| 10        | BOM draft                      | Phase 5 produces a BOM stub. Full BOM after first print informs sourcing.    |
| 11        | Physical validation protocol   | Phase F produces first-print protocol. Iteration after empirical data.       |
| 12        | README rewrite                 | Natural close-out after Phases 1–5 + F land. Premature now.                  |

After Phase F, revisit this table. The friend's review will likely still
be substantially right; the order and emphasis may shift based on what the
first print teaches.

---

## Recommended execution order

1. Phase 0 (workflow setup) — do this week.
2. Phase 1 (roadmap doc) — week of 2026-05-10.
3. Phase 2 (decision D19) — week of 2026-05-10 (combine with 1 in one
   review session if Hendrik's bandwidth allows).
4. Merge v6_2028_ready to main (separate human-driven action, NOT a
   Claude Code phase). Resolves D14–D18 onto main before Phase 4 builds
   on top.
5. Phase 4 (rim brush seals) — late May to early June.
6. Phase 5 (vacuum O-ring explicit) — early to mid June.
7. Phase F (print prep) — mid June.
8. Physical print + benchtop test — late June.
9. Reassess deferred phases against empirical data — early July.

Total elapsed: ~6 weeks of part-time work, gated by Hendrik's review
bandwidth, not by Claude Code throughput.

---

## Per-phase template (for any new phase added later)

```
## Phase N — <title>

**Why.** <1–2 sentences>

**Branch:** `phase-N-<slug>`

**Prompt:** [follows the universal startprompt + phase-specific tasks +
acceptance criteria + PR summary requirement]

**Acceptance criteria.** <bulleted list>

**Estimated time.** <range>

**Risks to flag in PR summary.** <bulleted list, optional>
```

End of prompt plan.

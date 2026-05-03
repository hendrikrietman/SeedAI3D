# SeedAI3D — Agent Instructions

This file is the canonical instruction set for AI coding assistants working
on this repository (Anthropic Claude Code, OpenAI Codex, Gemini Code, etc.).
It is kept identical to `CLAUDE.md` at the repo root — see "File sync" at
the bottom.

## Project overview

SeedAI3D is an AI-augmented, 3D-printable, breeder-first vacuum precision
sowing element. It is designed for plant breeders working small research
plots with frequent line changes and zero-contamination requirements — not
for industrial agriculture. Commercial precision seeders (Monosem,
MaterMacc, Stanhay) cost €5,000–25,000 and target thousand-hectare farming;
SeedAI3D fills the breeder-shaped gap at an estimated €50–150 per element
in printed parts, electronics, and small parts.

The repository contains parametric OpenSCAD designs, a vendored Three.js
interactive viewer (real-time animated cycle visualization), build
documentation, and architecture decisions. Distinguishing features:
vacuum pickup from a bottom seed-pool (Earthway / MaterMacc style),
zero-loss recovery bowl, dual-tube self-cleaning between lines, parametric
adaptation to soybean / edamame / lima / snapbean, and optional RTK GPS
plot-tracking integration. Status: digital prototype phase, first 3D-print
pending.

## Project memory — non-negotiable dimensions

- Disc OD 120 mm (132 mm with tooth rim), thickness 4 mm
- Central hole 50 mm Ø
- 40 pickup holes on R=42 mm, **perpendicular to disc plane** (not world-vertical — common bug). Hole diameter is parametric per crop profile (soybean Ø4 mm; see `scad/lib/parameters.scad` for current value).
- 60 teeth on disc-rim, modulus 1.5
- Disc tilted 45° from horizontal
- Reservoir (bottom seed-pool) wall slope ≥35°
- Housing 180×180×60 mm, 3 mm PETG transparent (legacy V4 housing; current v5.x uses an integrated round mal-plate, see D11 / v5.8.5)

## Project memory — reference frame

- World: X = left/right, Y = front/back, Z = up
- Disc centre at origin after rotation
- Disc tilt: `rotate([45, 0, 0])`; disc-normal = (0, −sin45°, cos45°) ≈ (0, −0.707, +0.707) (D1)
- Disc FRONT face = −DISC_NORMAL = (0, +0.707, −0.707). Seeds press against it.
- World coords on R=42 pickup-hole circle: `(R·cosθ, R·sinθ·cos45°, R·sinθ·sin45°)`
- **V5 architecture (D6):** vacuum pickup from a bottom seed-pool — not a top reservoir.
- Pickup (red) at θ=270° → (0, −29.7, −29.7) — disc dips into seed pool
- Release (orange) at θ=90° → (0, +29.7, +29.7) — directly above central drop hole
- Seed travels 180° along disc rim, pickup → release. Travel direction = θ decreasing (Option 1).

## Authoritative documents

When working on this repository, treat these three documents as the source
of truth. Read them before any code change.

- **`docs/prompt_plan.md`** — authoritative phase plan. Every code change
  belongs to a numbered phase with its own branch, prompt, and acceptance
  criteria. Do not invent phases or merge work across phases.
- **`docs/decisions.md`** — architectural decision record. D-numbered
  entries (D1, D2, …) capture every load-bearing design choice and its
  rationale. Cross-reference existing D-numbers when writing new entries
  and supersede explicitly rather than silently.
- **`docs/build_log.md`** — chronological log. Every phase commit appends
  one entry summarising what changed, validation count, STL stats, and
  open follow-ups.

Secondary references: `README.md` (public-facing project description),
`docs/audit_report_v5.md` (post-Phase-5 read-only inventory),
`scad/lib/parameters.scad` (the single source of truth for every
dimension), `validation/geometry_check.py` (the gate every phase must
pass).

## Hard rules

Do not violate these even if asked:

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

## Workflow rules

- Create a new branch from `main` for the current phase. Branch name is
  given in the per-phase prompt in `docs/prompt_plan.md`.
- Read these files before any code change:
    - `README.md`
    - `docs/decisions.md`
    - `docs/build_log.md`
    - `docs/audit_report_v5.md`
    - `scad/lib/parameters.scad`
    - `viewer/index.html`
    - `viewer/viewer.js`
    - `validation/geometry_check.py`
- Make changes in the order: docs → SCAD parameters → SCAD modules →
  viewer → validation → re-run validation → update build_log → update
  decisions if architectural.
- Run `python3 validation/geometry_check.py` before declaring the phase
  done. Report the PASS/FAIL count.
- If validation fails, do not commit. Diagnose, fix, re-run.
- After all changes pass, commit with a message that begins
  `[phase-N]` where N is the phase number from `docs/prompt_plan.md`.
- End the session with a PR summary in this exact format:

  ```
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
  ```

Do NOT open the PR yourself. The human reviewer opens the PR manually on
github.com after inspecting the branch.

If at any point you are unsure whether an action is in scope for the current
phase, STOP and write your question to the chat. Do not improvise scope
expansions.

## File sync

`AGENTS.md` and `CLAUDE.md` at the repo root must contain identical
content. They exist under different filenames for the conventions of
different AI coding tools (`AGENTS.md` is the OpenAI Codex / generic
convention; `CLAUDE.md` is the Anthropic Claude Code convention). When
either file is updated, the other must be updated to match in the same
commit.

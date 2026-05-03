<!--
SeedAI3D PR template. The branch-per-phase workflow is described in
docs/prompt_plan.md and AGENTS.md. Fill every section; remove only this
comment block.
-->

## Summary

<!-- 1–3 sentences: what this PR does and why. -->

## Phase reference

<!--
Which phase from docs/prompt_plan.md this PR implements (e.g.
"Phase 0 — workflow setup", "Phase 4 — rim brush seals"). If this is
not a phase PR, write "ad-hoc" and explain.
-->

## Files changed

<!-- Bulleted list of files added / modified / deleted. -->

## Validation result

<!--
Paste the PASS/FAIL count from `python3 validation/geometry_check.py`
(e.g. "47/47 PASS, 0 FAIL"). If a phase changes the check count,
note baseline → new (e.g. "47/47 → 49/49 PASS"). Include FAIL details
if any check failed; phases must not be merged with FAILs.
-->

## Docs updated

- `docs/build_log.md`: <!-- one-line summary, or "no change" -->
- `docs/decisions.md`: <!-- new decision ID, or "no change" -->
- other: <!-- e.g. README.md, docs/prompt_plan.md, AGENTS.md, or "no change" -->

## Reviewer checklist

- [ ] Validation passes (PASS/FAIL count above matches `geometry_check.py` output)
- [ ] Soybean crop default still works (no parameter regression)
- [ ] No STL files were hand-edited; STL changes came from re-rendering SCAD
- [ ] No commits were pushed directly to `main`; this branch was opened against `main`
- [ ] Existing viewer toggles and seed-lifecycle logic preserved (unless this phase explicitly replaces them)
- [ ] `docs/build_log.md` updated with a new entry for this PR
- [ ] If architectural: `docs/decisions.md` has a new D-numbered entry

# Report export text fidelity

## Objective and problem

The Share Image PNG truncates secondary captions with ellipses while the
on-screen report card wraps the same text in full. Preserve the meaning of
the report in the exported image on iPhone and iPad across supported locales.

## Scope and constraints

- Authorized: fix the D1 report-export truncation from the IF-1 verifier
  handoff without changing insight templates, scouting statistics, or other
  report content. Preserve the original IF-1 `status: defects` verdict.
- Native-only app; no OpenCode simulator launch. Existing untracked `.claude/`
  and `tmp/` stay untouched. No push or PR.
- Branch: `feature/report-export-text-fidelity` from local `main` at `9ebf0ea`.
  Route: delegated direct for preparatory reading and any nontrivial edits.
  Forecast: under 150 authored changed lines; delivery: ask-on-risk.
- The app has no test target; do not fabricate a RED test. Use structural
  checks and the simulator verifier's exact-SHA exported-PNG inspection.

## Checklist

- [x] RE-1: Make the exported image render secondary report captions in full
  without ellipsis, preserving the on-screen report and report facts.
  Evidence: `.git/handoff/IF-1.md` D1, exported `Goal zones` caption in en
  and es-ES plus the es-ES perspective caption; es-419 export and dark mode
  have not been verified. Inspect the report card and ImageRenderer path;
  make the smallest layout correction. Run `swift test --package-path Domain`,
  generic iOS Simulator build and `git diff --check`. Hand the exact commit
  to Claude Code or Codex to compare the exported PNG (not only preview)
  against the on-screen captions on iPhone/iPad in en/es-ES/es-419 and
  light/dark. No full UI pass until that verification succeeds.
  Local implementation: added vertical fixed sizing to the five report
  captions in `TeamReportCardView` so constrained ImageRenderer layout can
  preserve wrapped text; no report copy or statistics changed. The explicit
  `.lineLimit(1)` applies to goal-cell labels, not these captions. No app
  test target exists, so no RED test was claimed. Domain tests passed
  (404 tests); generic iOS Simulator build succeeded; `git diff --check`
  passed. Work-unit commit: `773807e`.
  Claude Code verified the exported PNG (Save to Files, compared word for
  word with the on-screen report) at exact SHA `773807e`: pass on iPhone 17
  and iPad (A16) in en/es-ES/es-419, light and dark, for goalkeeper #12 and
  the empty goalkeeper report. No ellipsis or missing words; numbers, zone
  labels, 7 m line and footer unchanged. Not run: iPad empty-report exports
  in es-ES/es-419 dark mode; spoken VoiceOver output is out of simulator scope.
  RDD: the committed slice `9ebf0ea..773807e` (medium, 3 paths / 72 lines;
  untracked `.claude/` and `tmp/` excluded through STATUS
  `--untracked-scope exclude`) received user consent and an approved one-lens
  review; lineage `review-a04fa5ceda87d199` was acknowledged. Advisory
  findings, triaged with no code change: R3-001 (no automated export-layout
  test) is the documented no-test-target exception, covered by the exact-SHA
  exported-PNG verification above; R3-002 (`.fixedSize` on the 7 m `Group`)
  is behavior-equivalent, because `Group` applies modifiers to each child and
  its only children are `Text` views. Fast-forwarded locally into `main` at
  `773807e`; post-merge Domain tests passed (404 tests) and the generic iOS
  Simulator build succeeded. `main` pushed to `origin` at `773807e`.

## Evidence and next step

- IF-1 insight-only behavior passed at `70c1776`; its RDD slice through
  `9ebf0ea` was acknowledged. D1 was observed on the candidate but not
  independently replayed at the base; the report renderer did not change
  in IF-1. Treat the suspect `.lineLimit(1)` and fixed width as hypotheses,
  not established root cause.
- RE-1 is closed. The fix was vertical fixed sizing on the captions; the
  `.lineLimit(1)` hypothesis did not apply (it belongs to goal-cell labels).
  The IF-1 handoff keeps its historical verifier-owned `status: defects`;
  D1 is resolved here, not by rewriting that verdict.

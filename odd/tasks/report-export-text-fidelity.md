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

- [ ] RE-1: Make the exported image render secondary report captions in full
  without ellipsis, preserving the on-screen report and report facts.
  Evidence: `.git/handoff/IF-1.md` D1, exported `Goal zones` caption in en
  and es-ES plus the es-ES perspective caption; es-419 export and dark mode
  have not been verified. Inspect the report card and ImageRenderer path;
  make the smallest layout correction. Run `swift test --package-path Domain`,
  generic iOS Simulator build and `git diff --check`. Hand the exact commit
  to Claude Code or Codex to compare the exported PNG (not only preview)
  against the on-screen captions on iPhone/iPad in en/es-ES/es-419 and
  light/dark. No full UI pass until that verification succeeds.

## Evidence and next step

- IF-1 insight-only behavior passed at `70c1776`; its RDD slice through
  `9ebf0ea` was acknowledged. D1 was observed on the candidate but not
  independently replayed at the base; the report renderer did not change
  in IF-1. Treat the suspect `.lineLimit(1)` and fixed width as hypotheses,
  not established root cause.
- Next: inspect the report rendering implementation, make the narrow fix,
  and request exact-SHA simulator export verification before review/closure.

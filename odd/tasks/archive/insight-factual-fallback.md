# Insight factual fallback

## Objective and problem

Show only deterministic, localized scouting insight templates. The generated-note
numeric guard accepts text that assigns valid counts to the wrong outcome;
invented-number rejection does not establish factual attribution.

## Scope and constraints

- Authorized: remove generated insight paraphrases and their unused numeric guard;
  keep the existing English, es and es-419 template behavior and card display.
- Do not change scouting statistics, other UI, catalogs, or unrelated advisories.
- Native-only app; do not run a simulator in OpenCode. Leave existing untracked
  `.claude/` and `tmp/` intact. No push, PR or merge.
- Work-unit route: delegated direct, because app and Domain sources/tests need
  coordinated edits. One bounded writer owns implementation.
- Forecast: under 300 authored changed lines (mostly removal); delivery strategy:
  ask-on-risk. Branch: `feature/insight-factual-fallback` from `d0db49d`.

## Checklist

- [x] IF-1: Replace generated-note display with the localized deterministic
  template and remove the unused model adapter and numeric guard with its tests.
  Acceptance: both cards still show their locale's template; no model request or
  guard remains reachable; reproduced count swaps cannot reach the UI via prose.
  Checks: existing Domain template/localization tests, full
  `swift test --package-path Domain`, generic iOS Simulator build, `git diff --check`,
  parent spot check. Test-first exception: the app has no test target and the
  correction removes an unsafe generation path rather than adding Domain behavior;
  use existing deterministic template tests as behavioral proof, not fabricated RED.
  Verified locally: `swift test --package-path Domain --filter LocalizationTests`
  passed (6 tests; parent repeated it), `--filter InsightWriterTests` passed
  (9 tests), full `swift test --package-path Domain` passed (404 tests),
  generic iOS Simulator build passed, and `git diff --check` passed.
  Claude verified the insight text on iPhone and iPad in en/es-ES/es-419,
  light/dark, at exact SHA `70c1776`: localized figures matched the card,
  including singular samples, and no generated prose appeared after waiting.
  Work-unit commit: `4e41ed0`.
  RDD committed-only assessment from `d0db49d`: medium, 5 paths / 262 lines,
  `review_due: false` (`under_budget`). The final committed slice
  `d0db49d..9ebf0ea` received user consent and an approved one-lens native
  review (0 findings); lineage `review-988ab7c338b0cb5a` was acknowledged.
  The feature branch was fast-forwarded locally into `main` at `9ebf0ea`.
  Post-merge Domain tests passed (404 tests), the generic iOS Simulator build
  succeeded, and the parent repeated LocalizationTests (6 passed). No push.

## Evidence and next step

- Read-only reproduction at `d0db49d`: changing 3 overall goals to 2 while
  moving 2 zone goals to 3 passed `InsightNumberGuard.accepts`; an invented 9
  was rejected. Optional pattern counts permitted another attribution swap.
- User chose template-only accuracy over paraphrase with residual semantic risk.
- Claude's broader IF-1 handoff remains `defects`: D1 is truncated secondary
  text in the Share Image export (English and Spain Spanish; es-419 export not
  verified). The report renderer and fixed-width card are unchanged from
  `d0db49d`; D1 was observed only on the candidate, not separately replayed
  on the base. The user explicitly chose to
  handle it as a separate report-export task, not widen IF-1. Preserve the
  verifier's `defects` verdict; the insight-only acceptance is scoped, not a
  full UI pass. Number-confirmation entry and spoken VoiceOver were
  unverified due to simulator input/accessibility limitations.
- IF-1 is closed for its insight-only scope. D1 remains a verifier-owned
  `defects` finding in `.git/handoff/IF-1.md` and is tracked separately in
  `odd/tasks/report-export-text-fidelity.md`; no full report-export pass is
  claimed.

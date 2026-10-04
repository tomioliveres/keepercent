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

- [ ] IF-1: Replace generated-note display with the localized deterministic
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
  Visual checks on the exact commit remain pending. Work-unit commit: `4e41ed0`.
  RDD assessment/outcome: pending until visual handoff is resolved.

## Evidence and next step

- Read-only reproduction at `d0db49d`: changing 3 overall goals to 2 while
  moving 2 zone goals to 3 passed `InsightNumberGuard.accepts`; an invented 9
  was rejected. Optional pattern counts permitted another attribution swap.
- User chose template-only accuracy over paraphrase with residual semantic risk.
- Next: delegated implementation and functional verification, then assess the
  resulting candidate before any claim of review authority. Claude `/verify-ui`
  needs a ready exact-SHA handoff; do not request it yet.

# T6.10 — Dedicated penalty records

## Objective

Make 7 m throws discoverable in shooter and goalkeeper cards and team Scouting, without mixing penalty records with field shots or requiring a court-filter tap.

## Authorization and scope

The user authorized T6.10 on 2026-10-05. Add one shared, presentational section to existing screens: penalty attempts, outcome counts, correctly labelled effectiveness/save rate, and target heatmap. Reuse existing deterministic statistics and goal rendering. English source copy with Spanish and Latin American Spanish translations.

Exclude new navigation, duplicate height/side charts, persistence changes, match/club scopes, import, report redesign and accessibility automation. Preserve historical IF-1/T6.1 handoffs and preexisting untracked `.claude/` and `tmp/`.

## Work units

- [x] PC-0 Map current statistics, cards, localization and historical handoffs; reconcile the main ledger with its locator-only Engram mirror.
- [x] PC-1 Implement and locally verify the shared penalty section and regression coverage.
- [x] PC-2 Verify the exact committed UI externally, then assess/review the slice and close T6.10 locally; delivery remains separate.

PC-1 route: delegated direct. Trigger: three existing screen integrations, shared presentation and localization plus test preparation. PC-2 route: external visual verifier followed by parent-owned native lifecycle.

## Acceptance criteria

- Shooter and team effectiveness: goals / all penalty attempts.
- Goalkeeper and team save rate: saves / (goals + saves); posts and misses excluded from this denominator.
- Player and team attacking-side isolation preserved; no field shots enter penalty statistics.
- Empty penalties show no data, not 0%; post/miss-only save records show no on-target data.
- Inside targets and concrete misses are rendered without inventing thirds for legacy misses; total outcome counts retain all attempts.
- Shared section has no SwiftData or ModelContext dependency and is present in all three screens.
- Localized copy and percentage formatting remain correct in en, es and es-419.

## Checks and test policy

Strict Domain TDD comes from `CLAUDE.md`: any new Domain behavior requires observed RED → GREEN → REFACTOR using `swift test --package-path Domain`. Existing statistics are being composed without production Domain changes: regression tests may pass immediately; do not invent a RED. SwiftUI changes require external visual proof, not unit-test claims.

- `swift test --package-path Domain`
- `xcodebuild -project Keepercent.xcodeproj -scheme Keepercent -destination 'generic/platform=iOS Simulator' build`
- `git diff --check`
- Structural catalog audit for new English/es/es-419 keys and placeholder agreement.
- External exact-SHA visual check on iPhone/iPad, light/dark and supported locales, populated/empty and post/miss-only records.

## Delivery and recovery

Branch: `task/T6.10`; base/review boundary: `5c54b5917d0e063030a72d98a27328d9d04aee61`.
Forecast: approximately 350–400 authored changed lines for the compact heatmap/summary slice, excluding duplicate charts and demo changes. Delivery strategy: `ask-on-risk`; ask before committing if forecast/actual scope exceeds about 400. Do not omit tests or compress readable catalogs to meet this advisory budget.
RDD observed on, global source, 2026-10-05; unchanged. UI verification preceded native review. The approved/acknowledged outcome is recorded below in the first work unit of the next task, preserving the frozen T6.10 tree.
No simulator launches in OpenCode, no push/PR/merge without authorization. Rollback: this dedicated section, its integrations, new catalog entries and regression tests, without changing existing linked-card behavior.

## Progress and next step

PC-1 locally verified. Added `SevenMeterSection` after the linked view on all three screens, five localized keys (en/es/es-419) and four composed penalty regression tests. Production Domain code and existing goal/court filters are unchanged. Implementation diff: 280 authored changed lines before task bookkeeping.

Observed proof: writer's focused suite 78 tests / 17 suites and full Domain suite 408 tests / 102 suites passed; generic iOS Simulator build succeeded for arm64/x86_64. Catalog audit passed: five new keys, 15 translations, matching placeholders, prior entries unchanged. `git diff --check` passed. Parent repeated the focused 78-test command successfully. Independent verifier ran `swift test --package-path Domain --filter PenaltyRecordTests`: four tests / one suite passed, and found no technical defect in the bounded inspection. Existing-behavior regression tests passed before presentation changes; RED exception applies, no fabricated failure.

Historical assessment sequence: initial native assessments were high/unassessable because preexisting untracked files had not been declared; this was not a confirmed severe finding or review approval. After obtaining the native inventory and explicitly excluding unrelated `.claude/` and `tmp/`, the intermediate committed-slice assessment from `5c54b59` returned medium, eight paths, 341 authored lines, `under_budget`. Its then-pending review state is superseded by the final closure evidence below. RDD remains on globally.

External verification: Claude Code recorded `pass` at exact `3c685d1bbffd89349b86096c0c3dcdd83a6a7866`, iPhone 17 and iPad Air 11-inch (M3), iOS 26.1. The authoritative handoff records screenshots and three inspection passes covering light/dark, en/es-ES/es-419, populated/empty records, isolated goal/save/post/miss examples, post/miss-only rates, an added field shot and court select/clear independence. No defects found in exercised checks. Real VoiceOver/accessibility-tree inspection and legacy-miss visual construction remain unverified; the latter has deterministic regression coverage. The existing Remove Player popover's lack of an explicit Cancel button is an out-of-scope observation, not a T6.10 defect.

Historical preflight limitation: without the untracked declaration, preflight returned an external schema-bound collection step whose JSON schema was unavailable in installed adapters. No JSON was guessed and no lifecycle authority was frozen in that attempt. The subsequent explicitly scoped lifecycle completed as recorded below; this is not an outstanding preflight instruction.

Known inherited limitation: drawn miss counts are not spoken in the existing goal accessibility values. T6.1 VoiceOver acceptance remains open; do not claim a visual or accessibility pass from build/tests.

Work-unit commit: `903f678079e31a46ad033c0c74cc94552c812119` (`feat(scouting): show dedicated penalty records`), 338 authored changed lines including tests and task bookkeeping. No delivery strategy escalation needed; no PR created.

## PC-2 closure and accepted advisories

T6.10 is locally closed on 2026-10-05. Parent-provided review evidence: committed-only slice from `5c54b5917d0e063030a72d98a27328d9d04aee61` through `d85afa581f854439b711d54bdb97c0c3eb009f4c`, eight paths / 346 authored changed lines, medium single reliability lens, consent granted, **APPROVED**. Lineage `review-c5a0fdf8489e834f` was acknowledged and its authority burned. New last reviewed boundary: `d85afa581f854439b711d54bdb97c0c3eb009f4c`. No review is pending for T6.10; do not reopen its acknowledged candidate.

The exact visual pass remains scoped to `3c685d1bbffd89349b86096c0c3dcdd83a6a7866` in `.git/handoff/T6.10.md`. Accessibility values/tree, spoken VoiceOver and visual legacy misses remain unverified. The preexisting iPhone Remove Player confirmation's lack of explicit Cancel remains an out-of-scope observation, not a T6.10 accepted defect.

Two accepted minor advisories are verified and applied in AX-1 on new `task/T6.1-A`, not on frozen `task/T6.10`:
- R3-redundant-sample: the private `penalties` property only forwarded `engine.sevenMeterShots` to another alias in `body`. Remove the property; retain `let sample = engine.sevenMeterShots` so summaries and heatmap share one filtered sample.
- R3-miss-nil-subloc: add one penalty record containing `.out(.wideRight, nil)` and `.out(.wideRight, .middle)`. Assert two attempts/two Out outcomes, one located middle miss, no nil-sublocation key and a located total of one. All five penalty tests passed before presentation cleanup; this is existing-behavior regression proof, not a RED/GREEN production fix.

The first new-task closure work unit is `cd7b18f713796c9e0dba30d9233477d2754bc890`; it precedes accessibility-test implementation `d84084e6066915a621820f57295a3cde1e41153f`. Local closure is not merge, push or delivery. Archive the authoritative T6.10 handoff in memory before removing the local metadata file, preserving its complete evidence and limitations. Continue AX-3 in `odd/tasks/accessibility-ui-tests.md`, not another T6.10 review. Parent owns full feature-document mirrors (`odd/penalty-card/tasks` and `odd/accessibility-ui-tests/tasks`); the oversized main ledger retains its locator-only mirror.

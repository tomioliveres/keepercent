# T6.10 — Dedicated penalty records

## Objective

Make 7 m throws discoverable in shooter and goalkeeper cards and team Scouting, without mixing penalty records with field shots or requiring a court-filter tap.

## Authorization and scope

The user authorized T6.10 on 2026-10-05. Add one shared, presentational section to existing screens: penalty attempts, outcome counts, correctly labelled effectiveness/save rate, and target heatmap. Reuse existing deterministic statistics and goal rendering. English source copy with Spanish and Latin American Spanish translations.

Exclude new navigation, duplicate height/side charts, persistence changes, match/club scopes, import, report redesign and accessibility automation. Preserve historical IF-1/T6.1 handoffs and preexisting untracked `.claude/` and `tmp/`.

## Work units

- [x] PC-0 Map current statistics, cards, localization and historical handoffs; reconcile the main ledger with its locator-only Engram mirror.
- [x] PC-1 Implement and locally verify the shared penalty section and regression coverage.
- [ ] PC-2 Verify the exact committed UI externally, then assess/review the slice and close T6.10 under ordinary repository policy.

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
RDD observed on, global source, 2026-10-05. Do not change it. UI verification precedes native review; no review or approval has been claimed.
No simulator launches in OpenCode, no push/PR/merge without authorization. Rollback: this dedicated section, its integrations, new catalog entries and regression tests, without changing existing linked-card behavior.

## Progress and next step

PC-1 locally verified. Added `SevenMeterSection` after the linked view on all three screens, five localized keys (en/es/es-419) and four composed penalty regression tests. Production Domain code and existing goal/court filters are unchanged. Implementation diff: 280 authored changed lines before task bookkeeping.

Observed proof: writer's focused suite 78 tests / 17 suites and full Domain suite 408 tests / 102 suites passed; generic iOS Simulator build succeeded for arm64/x86_64. Catalog audit passed: five new keys, 15 translations, matching placeholders, prior entries unchanged. `git diff --check` passed. Parent repeated the focused 78-test command successfully. Independent verifier ran `swift test --package-path Domain --filter PenaltyRecordTests`: four tests / one suite passed, and found no technical defect in the bounded inspection. Existing-behavior regression tests passed before presentation changes; RED exception applies, no fabricated failure.

Initial native assessment and the committed slice assessment were high/unassessable because preexisting untracked files had not been declared; this is not a confirmed severe finding or review approval. RDD remains on and the slice is treated as due, never low risk. Native inventory reconciliation, reassessment and review remain pending until external UI verification; no START or consent was invoked.

Known inherited limitation: drawn miss counts are not spoken in the existing goal accessibility values. T6.1 VoiceOver acceptance remains open; do not claim a visual or accessibility pass from build/tests.

Work-unit commit: `903f678079e31a46ad033c0c74cc94552c812119` (`feat(scouting): show dedicated penalty records`), 338 authored changed lines including tests and task bookkeeping. No delivery strategy escalation needed; no PR created.

Next: use the shared Git-common-directory handoff `handoff/T6.10.md` to verify the exact recorded SHA in Claude Code or Codex desktop. Stop here until the external verdict is available; T6.10 remains open on the main checklist. Source and task writes are not atomic with memory: mirror this full document at `odd/penalty-card/tasks`; the oversized main ledger remains authoritative with its existing locator-only mirror.

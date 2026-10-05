# T6.1-A — Repeatable drawn-region accessibility checks

## Objective and authorization

Add native XCTest UI coverage for the existing drawn goal/court accessibility contract, including labels, element roles, activation, no-data readings, query order and accessibility audits. Automated inspection does not prove spoken VoiceOver traversal.

The user authorized T6.1-A on 2026-10-05 and explicitly approved one coherent unit exceeding the advisory 400-line budget. No PR, merge or push. OpenCode must not boot a simulator or execute simulator tests.

## Scope

- Start `task/T6.1-A` from `d85afa581f854439b711d54bdb97c0c3eb009f4c`, without extending frozen `task/T6.10`.
- First commit records T6.10 closure, granted consent, approved/acknowledged lineage `review-c5a0fdf8489e834f`, medium single reliability lens, visual pass at `3c685d1`, and the new reviewed boundary `d85afa5`.
- Preserve unverified accessibility values/spoken VoiceOver and visual legacy misses; note preexisting iPhone Remove Player confirmation without an explicit Cancel button.
- Verify and apply only supported advisories: eliminate the penalty-filter alias, and cover legacy/concrete wide-right misses within one record.
- Add one UI-testing target and focused tests using existing in-memory launch routes, plus minimal stable identifiers needed to distinguish goal/court scopes.
- No new persistence, statistics, demo fixtures, navigation, geometry or intended VoiceOver behavior. No automatic fix or suppression of audit findings.

## Work units and routing

- [x] AX-0 Verify prior closure and map existing accessibility/test infrastructure.
- [x] AX-1 Implement and locally verify T6.10 closure bookkeeping and supported advisories; first new-task commit pending the parent.
- [ ] AX-2 Add native UI-test target, tests and minimal instrumentation; compile and prepare an exact-SHA external handoff.
- [ ] AX-3 Execute the UI tests and inspect the UI externally, then perform task-close native review. Delivery remains separate.

AX-1: delegated direct; preparatory reading plus a meaningful Domain regression and bookkeeping. AX-2: delegated direct; project/scheme wiring, UI tests and multiple accessibility instrumentation files. One writer at a time. AX-3: external simulator verifier, then parent-owned native review.

## Acceptance and checks

- Goal entry regions are named actionable elements; linked goal regions are readings, not buttons.
- Court contains valid near/far origins and a separate 7 m mark, never a forbidden 6 m shot action.
- Selected-region activation preserves existing callbacks and linked filter select/clear behavior.
- Shooter/keeper values retain their different denominators; empty samples say no data, never a fabricated 0%.
- Query-order assertions distinguish rendered accessibility-tree inspection from spoken VoiceOver proof.
- `performAccessibilityAudit()` runs on settled named screens without blanket issue suppression.
- Tests use isolated in-memory data and deterministic English labels; localization and real VoiceOver remain separately verified.

Strict Domain TDD source: `CLAUDE.md`; runner: `swift test --package-path Domain`. The supported legacy/concrete regression exercises existing behavior: observe whether it already passes, never fabricate RED. New Domain production behavior is out of scope.

Local commands (foreground):
- `swift test --package-path Domain --filter PenaltyRecordTests`
- `swift test --package-path Domain`
- `xcodebuild -project Keepercent.xcodeproj -scheme Keepercent -destination 'generic/platform=iOS Simulator' build`
- `xcodebuild -project Keepercent.xcodeproj -scheme Keepercent -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DerivedData build-for-testing`
- `git diff --check`

UI-test execution is external and remains pending after compile-only proof. Record unavailable/failed checks explicitly. A compile success is not an accessibility or UI-test pass.

## Delivery and recovery

Forecast: 350–500 authored changed lines, with readable project wiring/tests and bookkeeping. Delivery strategy: `exception-ok`, explicitly approved by the user; no PR/merge/push. Do not compress code or omit tests to meet the heuristic.
Reviewed boundary: `d85afa581f854439b711d54bdb97c0c3eb009f4c`. Every new native assessment/preflight must use this base and `--committed-only`. If untracked inventory requires collection, obtain the native digest then rerun STATUS with explicit exclusion; never invent selection JSON.
Preserve preexisting untracked `.claude/` and `tmp/`, historical IF-1/T6.1 handoffs, and the authoritative T6.10 pass until its closure record is committed and archived.
Rollback: only the new test target/scheme registration, test file, minimal identifiers and accepted advisory changes; existing accessible geometry remains unchanged.

## Progress and next step

AX-0 and AX-1 implementation complete on `task/T6.1-A` from reviewed `d85afa581f854439b711d54bdb97c0c3eb009f4c`. AX-1 is not yet committed; no commit identity is claimed. T6.10 is checked off in the main ledger and PC-2, using the parent-provided approved/acknowledged review evidence. Historical assessment/preflight proof remains, with stale current review-pending instructions resolved. Local task closure does not imply merge, push or delivery.

### AX-1 advisory assessment and observed proof

- R3-redundant-sample supported by direct usage inspection: private `penalties` only returned `engine.sevenMeterShots`, then `body` aliased it again. Removed only the private property and kept one body-local `let sample = engine.sevenMeterShots`; summaries and heatmap continue to share the filtered sample.
- R3-miss-nil-subloc supported: existing post/miss-only coverage combined a located wide-left miss with a legacy wide-right miss, but did not distinguish nil and concrete sublocations for the same direction in one penalty record. Added dedicated `legacyAndLocatedMissesInSameDirection` with two wide-right penalties. Assertions: attempts and Out count two, middle count one, nil key absent, located sum one.
- Test-first regression exception: the new test was added before presentation cleanup. `swift test --package-path Domain --filter PenaltyRecordTests` passed five tests / one suite immediately on existing behavior. No RED was observed or fabricated; no production Domain change was needed.
- After alias cleanup, `swift test --package-path Domain` passed 409 tests / 102 suites, including the new regression and alternate empty/post-only, side-isolation and inside-sample cases.
- `xcodebuild -project Keepercent.xcodeproj -scheme Keepercent -destination 'generic/platform=iOS Simulator' build` reported BUILD SUCCEEDED for arm64/x86_64. This is compile-only proof, not simulator or accessibility proof. Xcode emitted its no-AppIntents-dependency metadata-extraction warning; the build succeeded.
- `git diff --check` exited 0 with no whitespace errors in the tracked diff; the untracked feature document was also inspected directly.

Only the five AX-1 allowed files were edited. No XCTest target, schema, stable identifiers, localization or geometry changes. No simulator, lifecycle, staging, commit, branch, merge or push operation was run by the writer. The authoritative `.git/handoff/T6.10.md` and unrelated `.claude/`/`tmp/` remain untouched. Accessibility values/tree, spoken VoiceOver and visual legacy misses stay unverified; the preexisting iPhone Remove Player confirmation without explicit Cancel remains outside T6.10 defect acceptance.

AX-1 rollback boundary: the alias cleanup and new regression plus closure/progress entries in these task documents; unrelated accessibility geometry and historical proof remain intact. Runtime harness: N/A for this local regression/alias unit; no visible behavior is intended to change, and existing exact-SHA visual proof is historical only.

Next: the parent mirrors the full feature documents and creates the first new-task commit. Only after that commit exists may AX-2 add UI-test infrastructure and minimal instrumentation. Parent archives the T6.10 handoff after the closure commit, not before. Mirror this full document at `odd/accessibility-ui-tests/tasks`; the oversized main ledger keeps its locator-only mirror.

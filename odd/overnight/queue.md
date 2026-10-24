# Overnight queue

Tasks the unattended driver (`Tools/Overnight/run.sh`) may run, in order. Entry format, one line per task, then its details:

`- [ ] <ID> · auto · <model> — <title>` — `auto` makes it eligible; replace with `manual` to hold it. `<model>` is passed to `claude --model`.

A task is ticked by `/auto-task` in its close commit. Each **Acceptance** list is the definition of done. Never add `auto` to a task that needs the author's judgement.

## Test hardening (requested 2026-10-23: "que se lleve a casos máximos, extremos la prueba … que sea súper completa")

- [ ] T7.9 · auto · opus — UI test suite green
  - The author's spec in `odd/tasks/keepercent.md` (T7.9, including the T7.4 accepted debt) is authoritative; this entry only makes it executable unattended.
  - Acceptance:
    1. The full UI test target runs on the dedicated iPhone simulator through `Tools/check.sh` with zero unexpected failures.
    2. Each failure is classified as stale test, real defect or environment. Stale tests are fixed. **No product behaviour change**: each real defect becomes a new `manual` task line in `odd/tasks/keepercent.md` (and this queue), and its test is marked `XCTExpectFailure` naming that task, for the author to approve a fix later.
    3. Every expected failure or skip carries its reason in code and in the T7.9 ledger entry, as the author's spec requires. Blanket audit suppression is not allowed: `AccessibilityAuditPolicy` may only ignore `.textClipped`/`.contrast` on drawing identifiers.
    4. Split the scheme's tests into an `.xctestplan` with two configurations: `Smoke` (navigation and behavior) and `Audits` (accessibility audits), both run by default.

- [ ] T7.10 · auto · sonnet — Domain edge cases to the limit
  - Acceptance:
    1. Parameterized Swift Testing (`@Test(arguments:)`) over every `GoalTarget`, `CourtZone` and shot classification case, asserting round trips between persisted codes and domain values.
    2. Geometry boundaries in `GoalGeometry` and `CourtGeometry`: points exactly on every edge and corner, just inside and just outside, the origin, the far corner, negative and greater-than-one normalized values; each lands in exactly one documented region or is rejected.
    3. `StatsEngine` (including own-club statistics), `ScoutingPatterns` and `DeliveryConversionComparison`: zero shots, one shot, all shots in one zone, all goals, all saves, ties at every ranking threshold, minimum-sample boundaries (n−1, n, n+1), and a 10,000-shot input whose results equal a hand-computed aggregate.
    4. `Localization` and `DisplayNames`: 60-character names, emoji and combining characters, empty names, shirt numbers 0 and 99; every key in `Keepercent/Localizable.xcstrings` (source language English) has a Spanish translation that is not stale; a missing one is added.
    5. Domain only; strict TDD; any defect found is fixed in Domain with its test.

- [ ] T7.11 · auto · opus — Persistence round trips and upgrade safety
  - Acceptance:
    1. In-memory SwiftData tests (new test target or the existing `StoreCompatibility` package path) that save and reload every `Stored*` model with extreme values (empty and 200-character strings, numbers 0 and 99, dates at year boundaries) and compare against the domain values.
    2. `MatchHistoryUpgrade.run` is idempotent: running it twice yields the same store; running it on an empty store is a no-op.
    3. Deleting a rival team, a player and a match leaves no orphaned shots or participants, matching the app's confirmed-deletion rules.
    4. `Tools/StoreCompatibility/run.sh` no longer hardcodes an OpenCode temporary path: it uses `mktemp -d` under `$TMPDIR` and still passes.
    5. No change to the persisted schema in this task. A failure that needs a schema change finishes as `blocked` with the proposal.

- [ ] T7.12 · auto · opus — Stress fixture and end-to-end UI flows
  - Acceptance:
    1. A new Debug-only launch data mode `-KPData stress` (Domain-tested in `DebugLaunchConfiguration`, in-memory store only): 3 rival teams, one with 40 players including 60-character names and numbers 0 and 99, an own team with a full roster, 30 matches and about 3,000 shots spread over every zone, target, outcome and delivery.
    2. UI flow tests (the `Smoke` configuration), each starting from `empty` unless stated: create a rival team and add players; create a match and record a complete rival shot and a complete own shot; undo the last shot; delete a match through its confirmation; open each card on `demo` and change the scope selector; open the report preview and the share sheet on `demo`.
    3. Accessibility audits on `stress` at the default and the largest accessibility text size, on every launch screen (`teams`, `sessions`, `scouting`, `shooterCard`, `goalkeeperCard`).
    4. One `XCTClockMetric`/`XCTOSSignpostMetric` performance test that launches on `stress` and scrolls the matches list; record the baseline, do not assert an arbitrary threshold.
    5. Self-verify `stress` screenshots on iPhone light/dark at default and largest text size; nothing clipped, overlapping or truncated beyond the agreed two-line names.

- [ ] T7.13 · auto · opus — Snapshot tests for presentational views
  - Dependency authorized for this task: [`swift-snapshot-testing`](https://github.com/pointfreeco/swift-snapshot-testing) (test targets only, never the app binary). Why: presentational views draw plain domain structs, so image snapshots give deterministic visual regression checks that a model's screenshot judgement cannot.
  - Acceptance:
    1. A unit test target for the app that snapshots `GoalView`, `CourtView`, `LinkedZonesView`, the shooter and goalkeeper card contents, the shot-entry context panel and the shared report image.
    2. Matrix per view: iPhone and iPad widths × light and dark × text sizes `.large`, `.accessibility3` and `.accessibility5` × `demo`, empty and `stress` data where the view takes data.
    3. References are recorded once, every reference image is read and judged against the standard visual checks before it is committed; defects are fixed in the view first. Snapshots pin the simulator device and OS in the test and document how to re-record.
    4. Snapshots run in `Tools/check.sh`.

## Held for the author

- [ ] T7.5 · manual · opus — iPad and orientation (needs the author's visual judgement on the two-column layout).
- [ ] T7.14 · manual · opus — SwiftData `VersionedSchema` V1, `SchemaMigrationPlan`, and backup/export to a file (touches real stores; run attended).
- [ ] T7.6 · manual · sonnet — Polish F-21–F-27, F-31, F-39–F-41 (visual direction).
- [ ] T7.8 · manual · opus — Usability test with five handball people.

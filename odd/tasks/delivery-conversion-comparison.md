# T6.6 — Complete shooter delivery conversion

Compare overall standing and jump field-shot conversion in existing shooter patterns, with honest samples and localized wording. Keep cross/near-post findings grouped by sector and shooting hand; do not add depth subdivisions or redesign the interface.

## Scope and recovery

- Authorized by the user on 2026-10-13 after the T6.6 coverage audit.
- Branch: `task/T6.6-conversion-integration`, base `51a94e3b9ed933c0b3576f5bb6d81d4ee51322ed`.
- Historical Domain implementation: `b392476829073fdbec6ac5e98ebb67ca60fa5898` on `task/T6.6-delivery-conversion`; documentary tip `3bb8c4b431ab9fd0f59c84a078e03de5c5de27ba`.
- The historical native review was blocked before inspection; no approval or receipt exists. Preserve its branch and authority. Inspect/reuse only relevant source and tests, without merging unrelated historical bookkeeping.
- No persistence, schema, demo-data, new dependencies, layout redesign, remote operations, or simulator launch in OpenCode.
- Preserve unrelated untracked `.claude/` and `tmp/` and closed tasks with accepted debt.

## Behavior and acceptance

- Goals over all attempts for known standing/jump field shots; exclude 7 m and unknown delivery.
- Each group needs the existing comparison minimum (four); absolute rate gap needs the existing comparison threshold (0.3), with the established rounding tolerance.
- Keep both named x-of-y goal samples. Never confuse target frequency with conversion or imply causality.
- Production callers retain UUID-based person/match scoping. Preserve goalkeeper save comparisons.
- Add localized wording in English, Spanish and Latin American Spanish, using the existing pattern presentation and natural ranking. Keep the four-finding cap.
- Preserve sector-by-hand cross/near-post behavior. Existing goalkeeper weak/strong zone cards satisfy that part of T6.6 without duplicate prose.

## Work units

- [x] DC-2 Reconcile and reuse the historical calculation/tests; integrate the shooter finding and phrasing with observed Domain RED → GREEN → REFACTOR; run functional checks and commit the cohesive behavior. Work-unit commit: `402df5400392b3e09b0d56083f35de406724fda3`.
  - Route: delegated direct. Preparation and multiple nontrivial Domain/test/catalog/app files require one bounded writer.
  - TDD source: `CLAUDE.md`; runner `swift test --package-path Domain`.
- [ ] DC-3 Verify the exact committed UI in Codex, then perform the applicable native review and documentary closure. Do not check off T6.6 additions before observed acceptance.
  - Route: delegated verification/native provider actors when applicable; visual verification precedes review.

## Checks

- Focused comparison and pattern/phrasing suites, with exact commands/results recorded by the writer.
- `swift test --package-path Domain`
- `xcodebuild -project Keepercent.xcodeproj -scheme Keepercent -destination 'generic/platform=iOS Simulator' build`
- `git diff --check`
- Codex: qualifying shooter data (at least four shots in each delivery group and sufficient gap), honest samples/wording, empty/below-threshold behavior, English/Spanish variants and relevant iPhone/iPad layouts. Production demo data does not currently provide enough standing shots; handoff must specify reproducible manual entries rather than promise the finding in demo data.

## Delivery and progress

- Delivery strategy: `ask-on-risk`; initial forecast 300–380 authored changed lines, excluding generated content. Approximately 400 lines is advisory, not a reason to omit tests or compress readable code. Ask about delivery strategy before committing if the actual forecast/running count exceeds it.
- Functional checks passed in the writer tree committed as `402df5400392b3e09b0d56083f35de406724fda3`; parent repeated the comparison suite successfully (three tests, five parameterized cases). Visual acceptance and native review are pending. RDD is on (global); candidate consent remains human-owned.
- No merge, push or PR is authorized by this task record. Behavior commit: `402df54`, 254 authored changed lines across 11 files; the following progress record is documentation-only.
- Native assessment against explicit base `51a94e3`, committed-only, returned medium / `under_budget` (254 lines). An initial undeclared-untracked refusal was reconciled using the canonical inventory and explicit exclusion of unrelated `.claude/` and `tmp/`. No START, reviewer verdict, acknowledgement or receipt. Per project policy, offer the accumulated slice review at task close after visual verification.
- Rollback boundary: additive conversion API/finding, tests, phrasing/catalog entry and exhaustive presentation symbol plus scoped tracking notes.
- Next: Codex verifies the exact SHA in the shared handoff `T6.6-conversion.md`; OpenCode resumes DC-3 from its evidence before native review. Source bytes are unchanged by the documentary progress record.

## DC-2 implementation evidence (2026-10-13)

- Read historical helper and all 164 test lines through `git show`; reused its named immutable API, field-only calculation and rounding tolerance. Consolidated behavioral tests rather than restoring historical bookkeeping.
- RED: comparison tests failed on missing `deliveryConversionComparison`; integrated pattern/phrase tests then failed on missing `.deliveryConversion`. GREEN observed for the integrated scouting suite before final triangulation.
- Added shooter conversion to existing ranking and presentation, preserving all old sort keys, goalkeeper saves, delivery target preferences and the four-row cap. Goals use all known-delivery field attempts, including saves, posts and misses.
- DC-2 is committed as `402df54`. DC-3 visual proof and native review remain pending. No simulator, review, commit or handoff mutation was performed by the writer; parent owns the shared handoff.
- Final serial checks: `swift test --package-path Domain --filter DeliveryConversionComparisonTests` passed 3 tests (build 5.96 s, tests 0.002 s); `swift test --package-path Domain --filter ScoutingPatternsTests` passed 37 tests (0.61 s / 0.006 s); `swift test --package-path Domain --filter PatternPhraserTests` passed 8 tests (0.52 s / 0.016 s); `swift test --package-path Domain --filter LocalizationTests` passed 7 tests (1.54 s / 0.024 s); `swift test --package-path Domain` passed 464 tests / 111 suites (1.60 s / 31.444 s). Generic simulator `xcodebuild` succeeded; `git diff --check` passed. Build/diff wall-clock timing was not exposed by the tool. Existing unnecessary `try`/`await` compiler warnings and the AppIntents metadata-skip warning were observed; no unrelated catalog changes appeared.

### Disposable Codex data recipe

Use the committed SHA in a disposable debug empty store, not production/demo data. Create one match and one right-handed rival shooter; record eight field shots in the order below, with no approach recorded. Reuse that same shooter UUID for every shot. Origins are meters from center/goal line: left back near (-5, 8), right back near (5, 8), center near (0, 6), left back far (-6, 10).

| Shots | Delivery / outcomes | Origins in order | Targets in order |
|-------|---------------------|------------------|------------------|
| 1–4 | Standing / four goals | Left back near, right back near, center near, left back far | Top left, middle center, bottom right, top center |
| 5–8 | Jump / four saves | Repeat the same four origins | Repeat the same four targets |

Expected existing shooter Patterns row: `Standing: 4 of 4 goals; jump: 0 of 4 goals`, trailing `100% vs 0%` (locale spacing varies). Spain: `En apoyo: 4 de 4 goles; en suspensión: 0 de 4 goles`; Latin America: `A pie firme: 4 de 4 goles; en suspensión: 0 de 4 goles`. The matching Domain regression confirms this finding reaches the top four. Balanced targets/origins, fewer than five attempts per delivery and alternating targets avoid dominant target, sector-hand and repeat competitors. Before shot 8 the jump sample is below minimum and this row must be absent. Check iPhone/iPad wrapping and VoiceOver separately; no visual pass is claimed.

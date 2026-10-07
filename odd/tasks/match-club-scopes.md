# T6.11 — Match and club scopes

## Objective, authorization and constraints

Prepare the next task without extending the acknowledged T6.1-A tree. The user authorized this first work unit only: record T6.1-A closure and accepted verification debt, include the existing CLAUDE.md personal-project update, correct the local handoff log references, and apply only corroborated review advisories. Match/club feature implementation is not authorized by this closure request; investigate own-side player modelling before proposing its design.

No deadlines, merge, push, PR planning, simulator launch, or additional functional-verification rounds. Before any later PR planning, read `/Users/tomasoliveres/.config/agent-rules/pr-delivery.md` and ask the user. Artifacts remain English.

## Work units and route

- [x] MC-0 Record T6.1-A closure, its four acknowledged review slices and accepted debt; preserve handoff `status: unverifiable` and correct the second-reset references. Completed 2026-10-06; no new UI execution or lifecycle work.
- [x] MC-1 Replace the verified representative-point search duplication with one Domain implementation used by CourtView and its tests; verify behavior-preserving extraction and compile the consumer. Completed 2026-10-06 with observed missing-API RED, focused GREEN and final checks below.
- [x] MC-2 Parent structural readback and proportional checks: unchanged algorithm confirmed, focused test repeated successfully, whitespace check passed, draft assessment medium / under_budget. First work-unit commit and post-commit assessment receipt are recorded separately in Engram after the Git operations, without a follow-up bookkeeping commit.
- [ ] MC-3 Future: investigate own-side player modelling and resolve match/club scope design before implementation. Not started or authorized in this closure unit.

MC-0/MC-1: delegated direct, one bounded writer; triggers are preparatory reading and multiple non-trivial source/document files. MC-2: parent Git state/commit and spot check. MC-3 remains outside current authorization.

## Acceptance and verification

Closure: **functional matrix verified (AX-R9 8/8, five cases carried forward from 6258eb1), task-wide verification incomplete**. No claim of task-wide accessibility, audit or manual VoiceOver success. Record all ten advisory dispositions with source/log evidence before applying changes.

Strict Domain TDD source: CLAUDE.md. Runner: `swift test --package-path Domain`. First redirect existing independent-oracle tests to the proposed Domain API and observe the missing-API RED; extract the unchanged algorithm for GREEN, then remove duplicate helpers with tests green. No manufactured behavioral failure; this is an API/extraction regression, not new intended geometry behavior.

Required local checks, foreground, after any normalization:
- `swift test --package-path Domain --filter CourtGeometryTestsActivationContract`
- `swift test --package-path Domain`
- `xcodebuild -project Keepercent.xcodeproj -scheme Keepercent -destination 'generic/platform=iOS Simulator' build`
- `git diff --check`

These checks do not boot a simulator or reopen functional matrix verification. Parent repeats one reported quick command. No source-mutating normalizers are planned.

## Delivery and recovery

Branch: `task/T6.11`, starting from `8cb5920b075756f4a96c23b8019cbcd80890b2e2`, the reviewed boundary supplied by the user and review memory. T6.1-A stays frozen. RDD is on (global); assess the first committed unit with this explicit base and committed-only selectors. One review per task slice unless assessment is high; medium under-budget remains pending, not approved.

Forecast: approximately 180–300 authored changed lines for this closure/extraction unit (advisory estimate). Delivery strategy: ask-on-risk; no PR planning or publication authorized. Preserve unrelated untracked `.claude/` and `tmp/` and all existing verification artifacts. Rollback boundary: this unit's documentation and representative-search extraction only, not historical T6.1-A behavior/proof.

## Progress and next step

MC-0/MC-1 completed 2026-10-06 on `task/T6.11`; no commit made by the writer. Planning was read before edits; existing unrelated `.claude/`/`tmp/` and verification captures/logs were preserved. The existing CLAUDE.md personal-project update was preserved, adding only the authorized proportional-review/functional-evidence rule.

### Closure and advisory evidence

Master and feature check off T6.1-A with the explicitly incomplete task-wide scope; AX-R9.3 records observed external 8/8. Four supplied medium/granted/APPROVED reliability review slices are recorded as acknowledged/authority burned, not freshly invoked. Frozen branch: `task/T6.1-A`; next reviewed boundary remains `8cb5920b075756f4a96c23b8019cbcd80890b2e2`. Full-slice START's budget error created no authority and was resolved by those four reviews.

Locators: `odd/tasks/accessibility-ui-tests.md#current-closure--2026-10-06` (all ten compact advisory dispositions, reviewed final code and retained evidence); `.git/handoff/T6.1-A.md` (unchanged verifier status/metadata and history; only second-reset references corrected). `../keepercent-verify/build/TestResults/R9-scaffold-iPadA16-light.log:2206,2213–2215` was read directly and corroborates the correction. Raw review captures: `../keepercent-verify/build/rdd-T6.1-A-tramo{1..4}-capture.json` (user/Claude-supplied lineage evidence, no new lifecycle execution).

Accepted debt, not blockers and no new rounds: full twelve-test run, five audits, contrast/clipping, landscape, larger Dynamic Type, Spanish wrapping, shared-card obligations outside the five carried-forward cases, More-menu flake and intermittent-unexplained base :153 reset. Manual VoiceOver activation of all nine court Buttons remains **PENDING for the user by hand**; physical XCUI callbacks do not prove it. No unperformed audit, causality experiment or visual check is marked complete.

### Extraction and observed checks

`CourtGeometry.representativePoint(for:) -> CourtPoint?` now owns the unchanged vertex-mean/search algorithm. CourtView and activation-contract tests call this actual Domain API; duplicate private helpers are removed. Preserved vertex order, centroid calculation, `0...20`, division by `21`, classification, geometry, drawing, callbacks and local activation algebra. Test-side strict interior distance, ray casting and screen reconstruction remain independent.

- RED: redirected existing tests first; `swift test --package-path Domain --filter CourtGeometryTestsActivationContract` failed compilation because CourtGeometry had no `representativePoint` member at all three call sites. This is a real missing-API/extraction RED, not a behavioral failure or UI RED.
- GREEN: after adding the API, the same command passed **2 tests / 1 suite**, including eight parameterized zone cases, before duplicate removal.
- TRIANGULATE/REFACTOR: after removing duplicates, independent oracles still exercise overlapping far bounds, both wings, center-near versus 7 m, strict polygon edges and multiple canvas scales; final focused run passed **2 tests / 1 suite** (eight zone cases), 0.004 seconds.

Final commands ran serially, foreground, after all source changes; no normalization:

| Exact command | Observed result |
| --- | --- |
| `swift test --package-path Domain --filter CourtGeometryTestsActivationContract` | Exit 0; 2 tests / 1 suite, eight zone cases; 0.004 seconds. |
| `swift test --package-path Domain` | Exit 0; 416 tests / 104 suites passed, 6.111 seconds. |
| `xcodebuild -project Keepercent.xcodeproj -scheme Keepercent -destination 'generic/platform=iOS Simulator' build` | Exit 0; BUILD SUCCEEDED; changed Domain/app sources compiled and linked for arm64/x86_64. Existing nonfatal warning: `Metadata extraction skipped, no AppIntents.framework dependency found`. No simulator boot/UI execution. |
| `git diff --check` | Exit 0; no whitespace errors. Repeated after final documentation bookkeeping. |

Runtime harness: N/A for this behavior-preserving extraction; no new UI runtime round is authorized. These checks are local regression/compile evidence, not refreshed functional-matrix or VoiceOver proof.

Parent readback confirmed the unchanged search and preserved independent oracles; the repeated focused command passed 2 tests / 1 suite (eight zone cases), exit 0. Draft native assessment with the new task document included and unrelated untracked paths excluded returned medium / 221 authored lines / seven paths, `under_budget`; the initial unassessable result was resolved by explicit canonical inventory selection, not treated as low risk. No review START or consent was opened. The first work-unit commit includes this document; exact commit identity, final authored line count and committed-only assessment are recorded in companion Engram topic `keepercent/t6.11/closure-first-commit`, using this same reviewed boundary, rather than creating another bookkeeping commit.

**MC-3 is future, NOT started**; match/club feature implementation remains unauthorized by this closure request. Next: obtain authorization for that investigation before implementation. No merge, push or PR planning.

Mirror topic: `odd/match-club-scopes/tasks`; repository locator: `odd/tasks/match-club-scopes.md`. Full small-document mirror is requested after final readback; parent owns any pending memory judgments and post-commit synchronization. The repository file remains authoritative on mirror failure.

# T6.11 — Match and club scopes

## Objective, authorization and constraints

Historical first work unit (2026-10-06): prepare the next task without extending the acknowledged T6.1-A tree, record its closure and accepted verification debt, include the existing CLAUDE.md personal-project update, correct the local handoff log references, and apply only corroborated review advisories. That closure request did not authorize match/club implementation. The user separately authorized T6.11 implementation on 2026-10-07; the current contract below supersedes only the former future-work restriction, not historical verification evidence.

Historical closure-unit constraints: no deadlines, merge, push, PR planning, simulator launch, or additional functional-verification rounds. Before any later PR planning, read `/Users/tomasoliveres/.config/agent-rules/pr-delivery.md` and ask the user. Artifacts remain English.

## Work units and route

- [x] MC-0 Record T6.1-A closure, its four acknowledged review slices and accepted debt; preserve handoff `status: unverifiable` and correct the second-reset references. Completed 2026-10-06; no new UI execution or lifecycle work.
- [x] MC-1 Replace the verified representative-point search duplication with one Domain implementation used by CourtView and its tests; verify behavior-preserving extraction and compile the consumer. Completed 2026-10-06 with observed missing-API RED, focused GREEN and final checks below.
- [x] MC-2 Parent structural readback and proportional checks: unchanged algorithm confirmed, focused test repeated successfully, whitespace check passed, draft assessment medium / under_budget. First work-unit commit and post-commit assessment receipt are recorded separately in Engram after the Git operations, without a follow-up bookkeeping commit.
- [x] MC-3 Investigate own-side player modelling and resolve match/club scope design before implementation. Completed read-only on 2026-10-07; user confirmed one match per session, reusable rosters and optional own-team creation.

MC-0/MC-1: delegated direct, one bounded writer; triggers are preparatory reading and multiple non-trivial source/document files. MC-2: parent Git state/commit and spot check. MC-3 was outside the historical closure authorization; it is now completed under the separate implementation request.

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

Historical next step at closure (2026-10-06): MC-3 was not started or authorized. Current authorization and next step are recorded below; T6.1-A remains closed with accepted debt.

Mirror topic: `odd/match-club-scopes/tasks`; repository locator: `odd/tasks/match-club-scopes.md`. Full small-document mirror is requested after final readback; parent owns any pending memory judgments and post-commit synchronization. The repository file remains authoritative on mirror failure.

## Current implementation contract — 2026-10-07

The user authorized advancing T6.11 after the read-only model investigation and Steazzi comparison. Preserve current data, make club rosters reusable, and support individual match and historical statistics. One match is exactly one scouting session. Rival-only scouting remains available; an own team is optional and suggested when configured. Third-party screenshots remain local under ignored `reference/capturas-steazzi/2026-10-07/`.

### Behavior and data integrity

- Stable player identity must survive renumbering and reuse of a number by another player.
- A match suggests the current roster, then records its own participants and numbers. Later roster edits must not rewrite recorded match history.
- Archive historical players instead of destroying their associations; archived identities remain available for historical statistics.
- Scouting and player cards offer all-match/single-match scope. Reports retain that scope; a missing selected match never silently expands to all matches.
- Own shooter/goalkeeper attribution is optional. Legacy unidentified own-side data remains unidentified; never reconstruct people by guessing.
- Keep existing linked origin/target maps, deterministic statistics, no-data states and independent 7 m behavior.
- No third-party app dependencies, simulator launch, source publication, push or PR creation. Advanced trajectories, defensive pressure, numerical situation, clock, substitutions and subjective ratings are deferred. Championship tagging is not required for this slice.

### Remaining work units and routes

- [ ] MC-4 Rival match history and scopes: stable identity, safe existing-store upgrade, per-match roster snapshots, archiving, scope picker and scope-preserving report.
- [ ] MC-5 Optional own-team roster and shot attribution without blocking rival-only scouting.
- [ ] MC-6 My club player/goalkeeper cards across opponents with match/historical scope.
- [ ] MC-7 Exact-SHA external UI verification, native review and local closure; do not close T6.11 after only MC-4.

MC-3: delegated read-only mapping (unfamiliar relationships and evidence beyond the inline budget). MC-4/5/6: delegated direct, one bounded writer at a time (preparatory reading and multiple non-trivial files). MC-7: parent Git/state/spot checks and provider-selected native review, with UI inspection performed by Claude Code or Codex desktop only. Stop at each visible slice's ready handoff until external verification returns.

### Verification and compatibility gate

Strict Domain TDD from CLAUDE.md: observe RED, then GREEN, then REFACTOR with `swift test --package-path Domain`. Views have structural/build checks here, not fabricated UI proof.

- Run focused new Domain tests, then `swift test --package-path Domain`.
- Add a native development-only disk-store compatibility harness using frozen baseline models and actual production persistence. Prove legacy opening, retained links/counts, upgrade idempotence, snapshot continuity after renumber/archive/number reuse and reopen. In-memory demo stores alone are insufficient.
- If legacy opening or migration cannot be proven, stop without resetting or replacing the user's store. Added snapshot metadata can preserve only values still available at upgrade, not overwritten historical facts.
- Build with `xcodebuild -project Keepercent.xcodeproj -scheme Keepercent -destination 'generic/platform=iOS Simulator' build`.
- Run `git diff --check`; parent repeats one reported quick command.
- No source-mutating normalization is planned. Normalize before final checks and candidate freeze if needed.
- Exact-SHA visual verification precedes native review. Persist ready handoffs inside the shared Git common directory, not the source tree.

### Delivery, forecast and recovery

Selected strategy: `ask-on-risk`, resolved by the user to `feature-branch-chain` on 2026-10-07. Keep dependent units on the T6.11 feature line until the complete feature is verified. This authorizes local implementation/work-unit commits, not remote publishing or PR creation. Concrete remote PR boundaries remain unplanned and require separate authorization.

Forecast (advisory estimates, generated files excluded): MC-4 approximately 1,600–2,400 authored changed lines; MC-5 700–1,100; MC-6 500–900; whole feature 2,800–4,400. Keep coherent behavior/tests/docs together; do not compress or omit checks to meet a line budget. Record observed counts and any necessary slice refinement, not estimates as evidence.

Current start: `task/T6.11` at `8f2c1b44b21a1cf3f1876ed656d4bbe971d592b3`, also current main. Historical closure/extraction commit `0d07d1efe3f7f71776db1bb7185f0c91b59ae5f2` is integrated. RDD is on (global). Pending reviewed boundary remains `8cb5920b075756f4a96c23b8019cbcd80890b2e2`, per Engram `keepercent/t6.11/closure-first-commit`; medium under-budget is not approval. Use explicit committed-only assessment boundaries and record each unit's result. Preserve unrelated `.claude/`, `tmp/` and all historical handoffs.

Next: parent readback, local work-unit Git/review-boundary decisions and exact-SHA external UI handoff for MC-4. Local implementation is ready; MC-4 remains unchecked until external checks return. MC-5/6 were not implemented; T6.11 is not closed.

### MC-4 local implementation evidence — 2026-10-07

One bounded writer implemented rival-only match history inside the enumerated edit surface. Existing sessions remain matches; existing player rows and shot links remain intact. Optional additive UUID/archive/upgrade metadata and match-owned participant snapshots replace mutable roster projections. Production cards and patterns filter stable person identity; number-only Domain overloads remain explicit legacy/test compatibility. The Domain never generates player identities.

New matches suggest active players and allow selection/number drafts. Continuing an older match permits deliberate participant additions, but locks existing snapshots. Archiving never deletes shooting/facing associations; archived and former-role history remain reachable. Scouting and both cards select all matches or a stable match ID; same-date fixtures have distinct labels. Missing/empty selections stay empty. Scope changes reset linked origin selection. Reports carry the same scope and render its label into the shared image. New catalog keys include English, Spain Spanish and Latin American Spanish.

Observed strict Domain TDD, exact focused runner `swift test --package-path Domain --filter 'MatchRosterTests|MatchScopeTests'`:
- RED: missing MatchRoster/MatchScope/MatchShots APIs failed compilation before implementation.
- Behavioral RED: five tests ran; number-reuse repeat-after-goal incorrectly invented pairs across five different identities (one failure).
- Behavioral RED: seven tests ran; a number-only edit draft discarded the original roster identity (one failure).
- GREEN/TRIANGULATE: nine tests / two suites passed after both fixes, including same-person renumbering, different-person number reuse, snapshot immutability/validation, missing/empty/specific/all scopes, same-date isolation, on-target denominators and separate 7 m records.

Observed local checks before final bookkeeping (all foreground; final handoff repeats the complete required set after bookkeeping):
| Exact command | Observed result |
| --- | --- |
| `swift test --package-path Domain --filter 'MatchRosterTests|MatchScopeTests'` | Exit 0; 9 tests / 2 suites passed. |
| `swift test --package-path Domain` | Exit 0; 425 tests / 106 suites passed. |
| `bash Tools/StoreCompatibility/run.sh` | Exit 0; 1 disk-compatibility test / 1 suite passed, using a separate frozen-baseline process and actual production persistence sources. |
| `xcodebuild -project Keepercent.xcodeproj -scheme Keepercent -destination 'generic/platform=iOS Simulator' build` | Exit 0; BUILD SUCCEEDED for arm64/x86_64; existing harmless AppIntents extraction warning. Initial Section overload compile error was corrected before this pass. |

Compatibility boundary: frozen baseline `8f2c1b44b21a1cf3f1876ed656d4bbe971d592b3` model schemas generated a disposable disk store with one team, three players, two matches and three shots. Production opening retained all nine canonical persisted row identifiers, relationship links and primitive shot facts. Backfill created only the two participants evidenced by shot links, none for the unused roster player or empty match. Nil associations stayed nil. Repeated upgrade retained IDs/snapshots. Archive, renumber, rename, handedness change, number reuse by another person, new-match snapshots and reopening passed. Evidence is native macOS SwiftData runtime with SDK 27; this is not iOS runtime or visual proof. The initial identifier-wrapper equality assertion failed because decoded and managed-object-backed IDs differ; full canonical encoded IDs pass without changing migration behavior.

Backfill saves once, rolls back on failure and completes before seeding/UI. Startup errors never reset or replace a store. Historical snapshots can only capture facts available at upgrade; overwritten earlier facts are unrecoverable. Backfilled matches display that provenance. Only disposable harness stores were touched; no real user store or simulator was opened.

Rollback boundary: the MC-4 identity/snapshot/scope additions, their UI consumers, catalog keys, tests and development-only harness, before shipping upgraded stores. Once a store has been upgraded, returning an older app binary is not a proven store-downgrade path; do not reset data. Preserve MC-0/1 geometry extraction, historical closure evidence, parent planning, unrelated `.claude/`/`tmp/` and all handoffs.

Observed authored source/test/harness/catalog diff before this bookkeeping: 1,057 additions + 134 deletions = 1,191 lines across 37 paths, excluding generated output and the parent's existing planning change. Advisory forecast was not a cap; no checks or code were compressed to meet one. Suggested later review reading boundaries: Domain identity/scope contracts with tests; additive persistence plus disk compatibility evidence; roster/entry/scouting/cards/report integration with localization. These are reading boundaries, not worker commits or native review authority.

External UI verification and native review remain pending. Parent owns Git actions, exact-SHA handoff, one proportional spot check, assessment boundaries and review disposition. No simulator/UI tests, source publication, remote work, commits, staging or branch changes were performed by the writer.

### MC-4 bounded report correction — 2026-10-07

Independent technical verification found that the all-match report header reads the current goalkeeper number, but cached-image invalidation observed only shots, scope label and color scheme. A renumber could therefore change the visible header without refreshing the share image. Added only `onChange(of: goalkeeperNumber)` to the existing render path, which clears the cached image before rendering the current inputs. This is the accepted same-scope export correction before commit/freeze, not a new task or native review correction.

Views are not unit-tested per CLAUDE.md: structural readback/build verification applies, with no manufactured RED or multiwindow visual claim. The writer reruns the five delegated final commands after this correction/bookkeeping and returns each observed result in its handoff. MC-4 remains unchecked; external UI verification and native review are still pending. The parent's staged index and unrelated files are preserved; these two follow-up edits are intentionally unstaged for the parent.

### MC-4 committed receipt and verification handoff

Behavior work unit: `b769a9a507e4c7caf87aaa42f7c90a66a95a8c65` (`feat(scouting): preserve match rosters and scope player history`), 39 paths, 1,145 additions + 140 deletions = 1,285 authored changed lines including planning/bookkeeping. The preceding correction is included in this commit; the earlier unstaged description is historical worker evidence.

Final writer checks after correction: focused Domain 9 tests / 2 suites; full Domain 425 tests / 106 suites; native disk compatibility 1 test / 1 suite; generic iOS Simulator BUILD SUCCEEDED; whitespace check clean. Parent independently repeated the focused nine tests successfully and read the corrected report observer. A separate technical verifier inspected the complete staged diff and reran the disk harness: 1 test / 1 suite passed, 0.544 seconds. This is macOS persistence evidence, not iOS or visual proof.

Native committed-only assessment from pending boundary `8cb5920b075756f4a96c23b8019cbcd80890b2e2`: **high**, `process_boundary` / `shell_source` for `Tools/StoreCompatibility/run.sh`, 44 paths / 1,498 authored changed lines including the pending closure/extraction unit. `review_due: true`, `high_risk`; no consent, START, approved outcome or acknowledgement. The earlier unassessable draft was resolved with canonical unrelated-untracked exclusion, not treated as low risk.

External handoff: shared Git common directory `handoff/T6.11.md`, covering MC-4 only. Its exact final SHA includes this passive receipt; MC-5/6 remain unimplemented. Stop here for Claude Code `/verify-ui T6.11` or Codex desktop verification against that SHA. On return, reconcile the authoritative verdict before native review or further source edits; do not merge to main or close T6.11 yet. Post-commit receipt and handoff metadata are mirrored separately without pretending that a pending review passed.

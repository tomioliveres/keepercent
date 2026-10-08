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

### MC4-R1 — first external UI verdict correction plan

Authorized round 1 resumes MC-4 from `42f7f69d3a045d285a044db8cb81b93a7ede3468`. Read the authoritative `.git/handoff/T6.11.md` first: Claude's initial iPhone verdict and same-SHA iPad/root-cause follow-up constitute one first verdict, not two correction rounds. Preserve the complete verdict and its unexercised checks. MC-4/T6.11 remain unchecked; MC-5/6 stay excluded. Parent owns commits, updated exact-SHA handoff and native review; writer must not alter the handoff, boot a simulator, run UI tests, touch a real store, stage, commit, change branches, merge or publish.

Authorized edit surfaces only: `Domain/Sources/KeepercentDomain/DemoData.swift`, `Domain/Tests/KeepercentDomainTests/DemoDataTests.swift`, `Keepercent/Persistence/DemoDataSeeder.swift`, `Keepercent/Features/Teams/RosterEditorView.swift`, `Keepercent/Features/Sessions/MatchRosterSheet.swift`, and this task document. No normalization is planned. Rollback is confined to this round's fixture grouping/tests and roster/history presentation; retain existing MC-4 identity, snapshots, scope filters and migration proof.

- [x] R1-D1 Local fixture correction: `DemoData.matchShotIndices` is consumed directly by `DemoDataSeeder`. Retained the old halves partition through this production API for meaningful RED, then changed only membership to alternating original indices. Each populated match now contains 20 shots (10 rival, 10 own), seven facing #1, three facing #12 and four by #4. All 40 unchanged shot values/indices are assigned once; the third match stays empty. Scope/filter/statistics code was not changed. External UI re-verification pending.
- [x] R1-D2 Local presentation correction: capture initial choices once per sheet presentation instead of sorting selected drafts by edited numbers on each redraw. Deselecting disables the number row rather than removing it, preserving vertical tap targets; binding resolves by identity, not a potentially invalidated array index. Existing snapshots remain locked. Initial-source corroboration: `MatchRosterSheet.swift:11–16`. Structural/build evidence only; external interaction proof pending.
- [x] R1-D3 Local ordering correction: both history lists share number → trimmed case/diacritic-normalized name (fixed POSIX locale) → stable UUID ordering. Reused numbers and equivalent names have a stable tie-break. Initial-source corroboration: active history `RosterEditorView.swift:331` was unordered; archived `:309` sorted number only. External relaunch/order proof pending.
- [x] R1-D4 Local affordance correction: a shared plain full-row button shows the player, localized Shooter/Goalkeeper destination and disclosure chevron, using the session list's spacing/style. Shooter and facing history remain independent destinations, including former roles. Archived rows reuse the helper without being duplicated in active history. External visual/tap proof pending.
- [x] R1-D5 Supported elsewhere, not an archive-access defect: body includes `archivedPlayersSection` at `RosterEditorView.swift:136`; `:307–327` offers archived shooter navigation (`:315`) and goalkeeper navigation when current role or facing history warrants it (`:319–320`); destinations resolve at `:192–199`. Do not duplicate archived people in active history or remove their routes. This is source evidence, not fresh device proof.

Strict Domain runner: `swift test --package-path Domain`; focused runner: `swift test --package-path Domain --filter DemoDataTests`. Views have the CLAUDE.md structural/build exception, not fabricated UI RED/GREEN. Final foreground commands after all source/bookkeeping edits: focused DemoData tests, full Domain tests, `bash Tools/StoreCompatibility/run.sh`, `xcodebuild -project Keepercent.xcodeproj -scheme Keepercent -destination 'generic/platform=iOS Simulator' build`, and `git diff --check`. Any required failure means partial. Existing AppIntents extraction warning remains nonfatal. Reverification must cover populated match partition/scoped reports, selection/number-edit row stability, history order/affordances and archived destinations; all previously unexercised checks remain pending unless the external verifier observes them.

R1 observed TDD: `swift test --package-path Domain --filter DemoDataTests` executed 30 tests / nine suites. RED failed one new test with ten issues: each half had 20/0 or 0/20 rival/own shots and 0 versus 14/6 keeper samples, not the required 10/10 and 7/3. GREEN after membership correction passed all 30 tests / nine suites (0.008 seconds). The four new tests also triangulate unique complete fixture identities, unchanged original shot order/content reconstructed by original index, per-person/side/field/7 m/on-target totals summing to All and empty-match nil rates. This filter includes the existing demo suites; the initial red was behavioral, not missing-API compilation.

Final verification results after the last refactor/bookkeeping are supplied by the writer handoff, not presumed here. No new external UI result is claimed. Reverification should start with fresh isolated demo data: the seeder remains idempotent and deliberately does not rewrite previously seeded stores or user matches. Parent must commit and update the authoritative handoff to the new exact SHA before external re-verification; its current `defects` verdict and prior evidence remain untouched by the writer.

### MC4-R1 committed correction receipt

Correction commit: `b68b7d56e6d6884b59e27ff0d847f3e297369f81` (`fix(scouting): balance demo matches and stabilize history controls`), six paths, 185 additions + 44 deletions = 229 authored changed lines. Parent repeated `swift test --package-path Domain --filter DemoDataTests`: 30 tests / nine suites passed, and structurally confirmed production fixture membership and fixed row order. Writer final full Domain: 429 tests / 107 suites passed; disk harness one test / one suite passed; generic simulator build succeeded; whitespace checks clean. No simulator or new visual evidence.

Post-correction committed assessment from pending boundary `8cb5920b075756f4a96c23b8019cbcd80890b2e2`: high for the unchanged compatibility script shell/process boundary, 46 paths / 1,657 authored changed lines, review due. Review remains pending until exact-SHA external re-verification. The shared `handoff/T6.11.md` retains the original Claude verdict and will be ready for this first correction round; carry forward every unexercised check. If re-verification still returns defects, stop for the user's decision rather than automatically starting another correction round. MC-4 and T6.11 remain open, with MC-5/6 untouched.

### MC4-R2 — explicitly authorized second correction round

The user selected "Corregir otra vez" after the corrected-SHA external defects verdict, authorizing this one additional bounded round at `5e05964c346a9f6a72cded4f54a23b16b1bf18ae`. This overrides the previous one-round stop only for R2, not for automatic future corrections. Read the complete 145-line authoritative handoff and preserve its historical same-SHA partial/passing cases and unverified checks. MC-4/T6.11 remain unchecked; MC-5/6 excluded. Parent owns commits, new exact-SHA handoff and native review. If another defects verdict returns, stop for a new human decision.

Allowed edits only: `Keepercent/Features/GoalkeeperCard/GoalkeeperCardView.swift`, `Keepercent/Features/GoalkeeperCard/GoalkeeperCardContentView.swift`, `Keepercent/Features/Teams/RosterEditorView.swift`, `Keepercent/Features/Sessions/MatchRosterSheet.swift`, `Keepercent/Localizable.xcstrings` if necessary, and this document. No Domain, fixture, statistics, persistence/model/schema changes; no simulator/UI tests/real stores, Git mutations, remote work or native review. No formatters planned. Rollback is limited to this round's empty-card/report eligibility and hit-target/disabled presentation changes.

- [x] R2-D1 Locally implemented narrow improvement, not acceptance of the false identity claim. Source already displayed "No shots faced yet" (initial `GoalkeeperCardContentView.swift:67–73`); the debug fixture intentionally has `name: nil` (`KeepercentApp.swift:33–38`). Retained the honest #1 identity and scope picker. Truly zero-shot cards now have an explicit ContentUnavailableView instead of empty insights/maps/rankings; report navigation is disabled for zero attributable scoped shots or an unresolved person. Gate uses `engine.shots.isEmpty`, not save-rate/on-target denominator, so post/miss-only populated cards retain data/report access. Reused existing en/es/es-419 keys; no catalog or fixture changes. External empty-card/report proof pending.
- [x] R2-D2 Locally reinforced history-row bounds without changing labels/routes/archive ordering. Source already had frame → padding → contentShape inside the label (initial `RosterEditorView.swift:373–390`), so the failure was not a missing-modifier finding. Added a clear label background, explicit `.interaction` rectangle after full-width frame/padding, and full-width Button layout. Both active/archived lists reuse that helper. This is structural/build evidence; whitespace/edge taps still require external confirmation.
- [x] R2-D3 Locally clarified disabled presentation, not a claim that controls were enabled. Existing HStack disable predicate is retained. Deselected number rows now use secondary styling and reduced opacity without disappearing; immutable snapshots show a small lock symbol. Selected editable rows stay at full opacity. No new strings, row reordering, vertical shifts, identity/keyboard binding changes or new selection machinery. External visual/interaction proof pending.

Views-only structural/build exception per CLAUDE.md; no manufactured Domain/UI RED/GREEN. Final foreground commands after all source/bookkeeping edits: `swift test --package-path Domain --filter 'MatchRosterTests|MatchScopeTests'`, `swift test --package-path Domain`, `bash Tools/StoreCompatibility/run.sh`, `xcodebuild -project Keepercent.xcodeproj -scheme Keepercent -destination 'generic/platform=iOS Simulator' build`, `git diff --check`. Report observed counts; required failures mean partial, existing AppIntents warning nonfatal. Parent will update the authoritative handoff only after commit. Prior archive/reuse, entry/undo and count-split successes are carried historical evidence, never new R2 proof; unexercised cases remain pending.

Final local command results for R2 are delivered in the writer handoff after these edits, not predicted in this document. Reverify emptyGoalkeeper and selected empty match in light/dark and en/es/es-419, retained anonymous identity/scope, disabled report route, populated (including post/miss-only) cards/report availability, text/whitespace/edge history-row taps, and deselected versus locked number controls with reselect/edit checks. No new external pass, task closure, review authority or automatic third correction is claimed.

### MC4-R2 committed receipt

Human-authorized correction commit: `1919e34cb2e7c045b92c91e94d2faad800897e48` (`fix(scouting): clarify empty cards and history interactions`), five paths, 48 additions + 14 deletions = 62 authored changed lines. Writer final checks passed: focused Domain nine tests / two suites, full Domain 429 tests / 107 suites, macOS disk harness one test / one suite, generic simulator build and whitespace check. Parent inspected the complete correction diff and repeated the nine focused tests successfully. Views-only verification exception applies; the clear-background/interaction-shape changes are not a device-proven fix for row-edge taps.

Committed assessment from pending boundary `8cb5920b075756f4a96c23b8019cbcd80890b2e2`: high, unchanged shell/process boundary, 47 paths / 1,723 authored changed lines, review due. No consent, START or acknowledgement. The ready shared `handoff/T6.11.md` requests R2 exact-SHA external verification including this passive receipt, retaining all prior verdicts. Another defects verdict requires a new human decision; MC-4/T6.11 stay open and MC-5/6 remain excluded.

### MC4-R3 — authorized draft-retention correction

The user explicitly accepted the manual immutable-code finding at `6cd028c97d36d2be37cf6e8df2d6a2ae87ad4b7f` and subsequently confirmed restored quota after a writer launch failed before edits. This authorizes only this bounded correction: editing shirt 7 to 9, deselecting and reselecting currently appends the initial choice with shirt 7. The number setter edits only selected membership, so removing that member loses its draft. This affects New Session and unlocked additions to existing matches. It is distinct from the Jordi toggle candidate, closed by manual confirmation as a tap-injection artifact.

Exact edit surface: `Domain/Sources/KeepercentDomain/MatchRoster.swift`, `Domain/Tests/KeepercentDomainTests/MatchRosterTests.swift`, `Keepercent/Features/Sessions/MatchRosterSheet.swift`, and `odd/tasks/match-club-scopes.md`. No other source, schema, fixture, statistics, catalog or report edits. Parent owns Git, exact-SHA handoff and review. Native RDD remains blocked before START on the intended-untracked-selection/v1 schema; manual review is not native approval. Accepted partial UI coverage and every unexercised check remain debt. MC-4/T6.11 stay unchecked; MC-5/6 remain unimplemented. No automatic fourth correction round.

- [x] R3-D1 Local implementation: MatchRosterDraft retains latest values by stable identity independently of membership, with selected snapshots preferred over current roster values. Initial display choices stay immutable and sorted once by number then UUID. No generated identities or persistence changes.
- [x] R3-D2 Observed Domain RED/GREEN and seven new production-helper regressions cover off/on after 7→9, other people, repeated toggles, snapshot preference, fixed row order, locks, unknown/nil identities, cancellation value isolation and pending invalid/duplicate save validation.
- [x] R3-D3 Local integration: MatchRosterSelection uses the tested helper for toggle and number bindings, then publishes selectedPlayers to the existing parent value binding. Both New Session and existing Match Roster consume this view; save validation and disabled/locked presentation remain unchanged. Final serial foreground checks are reported in the writer handoff after this bookkeeping, not presumed here.
- [ ] R3-D4 Parent commits and supplies an exact-SHA external check: edit/deselect/reselect/save, including unlocked additions, locked snapshots and fixed order. Local tests/builds are not UI proof.

Strict runner: `swift test --package-path Domain`; missing-API RED is acceptable for the new production helper. Views have structural/build verification, not fabricated UI RED/GREEN. Final commands after source/bookkeeping edits: `swift test --package-path Domain --filter 'MatchRosterTests|MatchScopeTests'`, `swift test --package-path Domain`, `bash Tools/StoreCompatibility/run.sh`, `xcodebuild -project Keepercent.xcodeproj -scheme Keepercent -destination 'generic/platform=iOS Simulator' build`, `git diff --check`. Required failures mean partial; the existing AppIntents metadata warning is nonfatal. No simulator boot, UI tests, real stores, staging, commit, branch change, merge or publication.

R3 observed TDD, exact command `swift test --package-path Domain --filter 'MatchRosterTests|MatchScopeTests'`: RED exited 1 because MatchRosterDraft was missing at the new regression call site, before implementation; this is missing-API RED, not an executed behavioral or UI failure. GREEN exited 0 with 10 tests / two suites, including repeated 7→9/off/on and validated saved number 9. TRIANGULATE exited 0 with 16 tests / two suites (0.006 seconds) after six alternate/negative tests and view integration. No additional source refactor was necessary. Unknown UUID mutations are no-ops; nil suggestions are not selectable, while malformed selected values remain present so existing save validation rejects them. Invalid/duplicate numbers are not silently rejected while typing.

R3 is local only, with external edit/deselect/reselect/save proof pending. The parent must commit and update the shared exact-SHA handoff; its historical defects coverage label, manual Jordi confirmation and accepted unexercised checks are untouched. External check is bounded to New Session and an unlocked addition in Match Roster: edit 7→9, toggle off/on, confirm 9 remains and saves, with other participants, row order and existing locks unchanged. No broad simulator matrix repeat or task-wide pass is claimed. Rollback boundary is these four files' R3 draft behavior/tests/bookkeeping only; retain every earlier MC-4 correction and historical receipt.

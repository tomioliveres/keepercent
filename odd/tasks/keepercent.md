# Keepercent — task tracking

Feature document: [docs/mvp.md](../../docs/mvp.md) · Deadline: **Friday Sep 25, 2026**
TDD: strict mode enabled for the Domain layer (RED → GREEN → REFACTOR), Swift Testing.

## Day 0 — Sat Sep 19 (setup)

- [x] T0.1 MVP definition written (`docs/mvp.md`) — inline
- [x] T0.2 Repository scaffolding: `.gitignore`, `README.md`, `CLAUDE.md`, task file — inline
- [x] T0.3 Install Xcode — Xcode 27.0 (27A266a) installed; organizers confirmed iOS 26 as the minimum, so no Xcode 26 needed
- [x] T0.4 Create the Xcode project `Keepercent` — hand-written pbxproj (synchronized group, shared scheme, local Domain package); `xcodebuild ... build`: BUILD SUCCEEDED, `-target ...ios26.0-simulator -swift-version 6`
- [x] T0.5 First commit + GitHub repository — https://github.com/tomioliveres/keepercent (public)
- [x] T0.6 Daily update posted in `#daily-updates`
- [x] T0.7 Documentation pass: architecture explained from first principles in `docs/index.html` §06 (dependency rule, why `Domain/` is a separate package, screaming architecture, ports/adapters, container/presentational split, why no repository over SwiftData, the `StatsEngine`/`ModelContext` invariant), new `docs/index.html` §07 on build methodology (TDD, test scope, RDD vs testing, work-unit commits, sequential branch), decisions table extended, `docs/mvp.md` §8 and `CLAUDE.md` updated to match — direct inline (documentation-only, no source code touched, single author reviewing every line); verified: section numbering sequential (`rg -n '<span class="num">'`), HTML parses (`python3 -c "html.parser..."`), section/h3 tag counts balanced

## Day 1 — Sun Sep 20 (domain)

- [x] T1.1 `GoalTarget`: 3×3 inside grid, post segments, out directions + tests — delegated writer (2+ files); `swift test`: 11 tests / 55 cases passed
- [x] T1.2 `CourtZone` + `CourtGeometry`: sector from the angle at the goal centre (cuts at ±18°/±54°), depth from the distance to the **goal mouth** so it matches the drawn 9m line, `ShotOrigin` with the 7m case, persistence codes — delegated writer (4 files, TDD RED→GREEN→REFACTOR); `swift test`: 41 tests / 16 suites passed (parent spot check re-ran it); `gentle-ai review assess`: medium, RDD off → writer self-verification + spot check
- [x] T1.3 `ShotClassification`: `ShotSide`/`ShotHeight`/`ShotLine` derived from an origin/target pair; classification covers all three `GoalTarget` cases (post segments and out directions carry a side, crossbar -> `top`), height only where the vertical band inside the frame is known (every `out` case, `over` included, has none) — delegated writer, strict TDD with the RED run shown before GREEN (2 files); `swift test --package-path Domain`: 54 tests / 21 suites passed (parent spot check re-ran it); commit `59aa16f`; `gentle-ai review assess`: medium (`executable_change`, 309 lines) -> consent granted, lens `review-reliability` returned **approved** (lineage `review-5355880acf646521`, acknowledged, authority burned) with two non-blocking advisory findings, both verified against the code and applied as the follow-up commit: R3-001 replaced the `default` clause in `line(from:to:)` with explicit `(.left, .right), (.right, .left)` patterns so exhaustiveness is compiler-verified instead of test-verified, and R3-002 added the missing end-to-end assertion for `post(.crossbarCenter)` -> `.neutral`
- [x] T1.4 SwiftData models + mapping to domain values (primitive codes) — split into two work units because the Xcode project has a single app target and **no test target**: everything testable stays in `Domain/`, the `@Model` types are a thin shell over primitives (`docs/mvp.md` §8). `a5fbc55` domain value types (`Player`, `Handedness`, `SessionKind`, `AttackingSide`, `ShotDelivery`, `ShotApproach`, `Shot` with derived `origin`/`line`) — delegated writer, strict TDD, RED shown before GREEN; parent removed a redundant `NormalizedPoint` alias over the existing `CourtPoint` and a duplicate clamping suite, and renamed `Shot.classification` -> `Shot.line`. `eef4cb9` the initializer now drops an `originPoint` passed with `isSevenMeters`, making the contradictory pair unrepresentable instead of merely ignored. `3a5bee4` `Keepercent/Persistence/`: `StoredRivalTeam`, `StoredPlayer`, `StoredSession`, `StoredShot`, the schema and the container wiring — delegated writer; parent added the missing `@Relationship` inverses (`StoredPlayer.shotsTaken`/`.shotsFaced`, `StoredRivalTeam.sessions`) after verifying against Apple's SwiftData documentation that a delete rule reaches referencing rows only through an inverse, so the writer's claimed nullify behaviour was unsupported. `ef3056b` review correction: the decoding of stored codes moved into the domain as `Shot.init?(attackingSideCode:...)` and `Player.init(...handednessCode:)`, next to `GoalTarget.init?(code:)`. `36bb1b7` coverage held back from that bounded correction. Verified: `swift test --package-path Domain`: 79 tests / 30 suites passed (parent spot check re-ran it); `xcodebuild -project Keepercent.xcodeproj -scheme Keepercent -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1' build`: `** BUILD SUCCEEDED **`; app installed and launched on the simulator with the SwiftData container open (a build alone never proves a schema loads). RDD: `a5fbc55` assessed medium -> consent granted, lens `review-reliability` **approved** (lineage `review-018a519c56a99fde`, acknowledged) with two advisory findings, both verified and applied as `eef4cb9`. The `3a5bee4` slice assessed medium -> consent granted, lens `review-reliability` returned **`correction_required`** with two CRITICAL findings (R3-001, R3-002: the persistence mapping had no test at all); one bounded correction of exactly 200 lines answered both, targeted validation passed, **approved** (lineage `review-b6f5974c6d76aa26`, acknowledged, authority burned). `36bb1b7` assessed medium, 20 lines, deferred to the next slice.
- [x] T1.5 Demo data seed — one rival team, a ten-player roster and a full live session, built entirely from fixed inputs so the app opens on something that reads as real scouting. `7d23186` `Domain/Sources/KeepercentDomain/DemoData.swift` (388 lines) plus `DemoDataTests.swift` (246 lines): the dataset lives in the domain, where it is testable without a simulator, and the tests assert the *tendencies* rather than the rows — both attacking sides are represented, every shot respects the attacking-side invariant, the demo shooter's bias is a strict majority, origins resolve through `CourtGeometry`, and two evaluations are identical. No `Date()` and no randomness anywhere: `sessionDate` is built from explicit UTC date components, so the whole dataset stays on one calendar day whenever it is read. `40541e6` `Keepercent/Persistence/DemoDataSeeder.swift` (54 lines): a fetch limited to one row short-circuits when the demo team already exists, so the seed is idempotent across launches; the graph is assembled before `context.insert(team)`, because SwiftData follows the relationships from the single inserted root. Players are keyed by shirt number so a shooter and the goalkeeper facing them map to the same stored row instead of inserting a player twice. Verified: `swift test --package-path Domain`: 106 tests / 38 suites passed (parent spot check re-ran it); `xcodebuild -project Keepercent.xcodeproj -scheme Keepercent -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1' build`: `** BUILD SUCCEEDED **`. RDD: reviewed as one accumulated slice from the last reviewed boundary `ef3056b` with `--base-ref ef3056b --committed-only`, covering `36bb1b7`, `00dc358`, `df315bd`, `7d23186` and `40541e6` — the selectorless status would have started from `ce090d3` and re-dragged the whole already-acknowledged T1.4 block. Assessed medium (`executable_change` in `DemoData.swift`, 5 paths, 723 lines) -> consent granted, lens `review-reliability` returned **approved** (lineage `review-ed63edf490bcc819`, acknowledged, authority burned) with two non-blocking advisory findings and no blockers.

## Day 2 — Mon Sep 21 (components)

- [ ] T2.1 `GoalView`: drawing + hit-testing (frame areas enlarged beyond the stroke)
- [ ] T2.2 `CourtView`: drawing + hit-testing + 7m mark
- [ ] T2.3 Selection highlighting

## Day 3 — Tue Sep 22 (entry)

- [ ] T3.1 Rival team + roster editor, "+" tile for unknown numbers
- [ ] T3.2 Session setup (live | video)
- [ ] T3.3 Shot entry end to end: attacking side, active rival goalkeeper, optional chips
- [ ] T3.4 Shot log with undo/delete

## Day 4 — Wed Sep 23 (analysis)

- [ ] T4.1 `StatsEngine` + tests
- [ ] T4.2 Linked-view component (court ↔ goal) with Swift Charts
- [ ] T4.3 Shooter card
- [ ] T4.4 Rival goalkeeper card

## Day 5 — Thu Sep 24 (AI + sharing) · feature freeze tonight

- [ ] T5.1 `InsightWriter` protocol + template fallback + tests
- [ ] T5.2 `FoundationModelsInsightWriter` with availability check
- [ ] T5.3 Shareable report card (`ImageRenderer` + `ShareLink`)
- [ ] T5.4 Roster import: Vision OCR + PDFKit + review screen *(first to cut)*

## Day 6 — Fri Sep 25 (ship)

- [ ] T6.1 Bug fixing, iPad/iPhone polish, accessibility pass
- [ ] T6.2 README: screenshots/GIF, architecture, AI disclosure
- [ ] T6.3 Final commit, tag, submit the repository link

## Notes

- Dates in the day headings follow `docs/mvp.md` §10; the plan there is authoritative.
- Route per task (inline vs delegated) is recorded as work progresses.

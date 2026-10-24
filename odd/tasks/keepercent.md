# Keepercent — task ledger

One line per task. Product plan: [docs/mvp.md](../../docs/mvp.md) · Unattended queue: [odd/overnight/queue.md](../overnight/queue.md) · Workflows and closure rules: [CLAUDE.md](../../CLAUDE.md).

Full history up to 2026-10-24 (evidence, verification verdicts, reviews, design decisions) is preserved verbatim in [archive/keepercent-2026-10-24.md](archive/keepercent-2026-10-24.md); closed feature documents live in [archive/](archive/). A closed task's line names its merge commit or PR, gate, verification and review; details go in the commit message.

## Open

- [ ] T7.9 UI test suite green: make every UI test pass, or skip it explicitly with a recorded reason, before T7.6 starts.
  - Added by the author (2026-10-23) after a UI/UX status review. Evidence: in T7.2's r3 UI test run 4 passed and 13 failed. Three navigation/reveal failures reproduced at baseline; ten audit failures match historical T6.1-A symptoms but were not individually rerun at baseline. A permanently red suite no longer signals real regressions. Acceptance: run the full UI test target on the current `main`, classify each failure (stale test, real defect, environment), fix stale tests, file real defects as tasks, and mark any deliberately skipped test with its reason in code and here. No product behaviour change unless a real defect is approved for fixing. Ordered before T7.6; the number reflects when it was added, not its order.
  - T7.4 accepted debt (2026-10-24, author decision), to resolve or skip with a recorded reason here: iPad AX segmented Roster/Matches/Scouting control does not scale; "Potentially inaccessible text" OCR heuristic on Canvas heatmap text (AtLargestTextSize, GoalkeeperCard, iPad); iPhone roster "Text clipped" on Jordi Ferrer; contrast of names under the tab-bar scroll-edge fade.
- [ ] T7.10–T7.13 Test hardening (Domain edge cases, persistence round trips, stress fixture and UI flows, snapshot tests): specs in [odd/overnight/queue.md](../overnight/queue.md).
- [ ] T7.14 SwiftData `VersionedSchema` V1, `SchemaMigrationPlan` and backup/export to a file — in progress since 2026-10-24 in its own session (attended; touches real stores).
- [ ] T7.5 iPad and orientation: readable widths, two-column portrait entry, landscape verification (F-17).
  - Baseline (2026-10-21) closed separately as T7.5-baseline (`e8a8cd2`); landscape-right, rotation at the corrected SHA, named own shooter and the full matrix remain unverified. Investigation: [iPad landscape and goal corners](../../docs/ipad-landscape-goal-corners.md) (local file, not yet committed).
  - Design agreed with the author (2026-10-23, Claude Code design session while T7.4 awaited UI verification; no code yet). Scope grows beyond F-17: goal corners, a striped frame and a three-column card layout in iPad landscape.
    - Decision 1 (corners): each upper corner becomes ONE target shaped as an L, one third long on each arm, from the shooter's view and symmetric left/right. Frame corner = today's `crossbarLeft` + `leftPostTop` (the frame goes from 9 segments to 7). Outside corner = today's `out.wideLeft.top` + `out.over.left` + the high-and-wide diagonal; `over` keeps only `center`, wide misses keep `middle`/`bottom`. Every other target (inside 3x3, crossbar center, middle/bottom posts) is unchanged. Drawing, highlighting, hit-testing and the stored target must agree. Accepted cost: the post-top/crossbar-end and over-left/wide-top distinctions are no longer recorded. Rejected: a shorter L that keeps reduced old segments (old codes would become ambiguous).
    - Decision 2 (frame look): posts and crossbar are drawn in alternating charcoal and white bands like a real handball goal, with each corner's L band in one colour (it coincides with the Decision 1 corner). Dark mode: white and mid-grey bands with a thin outline. Rejected: red and white (pink selection would be hard to see on red, and red already means error/destructive in `Palette`). A per-team goal colour is out of scope.
    - Decision 3 (historical data): translate at read time, never migrate. Stored codes are left untouched; `GoalTarget.init?(code:)` decodes the eight old codes (`post.leftPostTop`, `post.crossbarLeft`, `out.wideLeft.top`, `out.over.left` and their right mirrors) into the new corner targets, which is exact because each old region lies entirely inside its new L. New shots save new corner codes. Legacy `out.wideLeft`/`out.wideRight` without a third stay unknown-third and are never guessed. Rejected: rewriting stored codes (irreversible, destroys detail, high risk) and a clean break (old codes would decode to `nil`, silently dropping shots and fixtures). The app is offline, so data lives only in each device's local store.
    - Decision 4 (iPad portrait entry): two columns, shooters over the context panel on the left and goal over court on the right, with the fixed outcome/undo bar at the bottom; it reuses the landscape three-column components and the `middleColumnHeights` sizing. iPhone keeps T7.2's single column.
    - Decision 5 (cards in iPad landscape): shooter and goalkeeper cards use three columns, with goal over court fixed in the centre and sized to the height (never side by side: it is what the shooter sees and matches shot entry). Left: header, insight text and patterns; right: 7 m, where they score and shot shape; side columns scroll independently and react to the zone selection. iPad portrait and iPhone stay stacked. Text and lists use one shared readable-width modifier (~700 pt); Scouting only gets the readable width. Team report sizing stays with T7.4 (F-18). Rejected: goal and court side by side.
- [ ] T7.6 Polish: F-21–F-27, F-31, F-39–F-41 ([UX audit](../../design/ux-audit/report.md)).
- [ ] T7.8 Usability test with five handball people after T7.7 and T7.2 (plan in the UX audit report, Part 2).
- [ ] T6.6 additions (user, 2026-10-03): patterns by delivery (standing vs jump: where and how well), by approach (moving left/right/straight: target side), cross vs near post per origin, preferred height/side, 7 m tendencies, handedness × wing, repeat-after-scoring (shot order by date), near vs far conversion, and the existing goalkeeper weak/strong zones. Minimum sample and clear share per finding; always show "x of y". Overall standing/jump conversion already shipped (DC-2/DC-3, 2026-10-19).
- [ ] T6.4 Demo video: a short screen recording of the colored app on the demo data, reused for social media and the README. Show Keepercent only, nothing from `reference/`. The author publishes.
- [ ] T5.4 Roster import (Vision OCR + PDFKit + review screen): deferred, not selectable. Unmerged `task/T5.4` keeps `f1af1b5` and `9be8827`; an open preservation defect (#11 lost after adding #99) and incomplete verification are recorded in the archive and `.git/handoff/deferred/T5.4.md`.
- [ ] Backlog: filters on cards (match, delivery, approach); edit any recorded shot, not only undo the last; PDF scouting report with PDFKit.

## Done

Before 2026-10-24 each task's evidence is in the archive under the same ID.

- [x] T0.1 MVP definition (`docs/mvp.md`)
- [x] T0.2 Repository scaffolding
- [x] T0.3 Install Xcode 27
- [x] T0.4 Xcode project `Keepercent`
- [x] T0.5 First commit and public GitHub repository
- [x] T0.6 Daily update posted
- [x] T0.7 Documentation pass
- [x] T1.1 `GoalTarget`
- [x] T1.2 `CourtZone` + `CourtGeometry`
- [x] T1.3 `ShotClassification`
- [x] T1.4 SwiftData models and domain mapping
- [x] T1.5 Demo data seed
- [x] T2.1 `GoalView`
- [x] T2.2 `CourtView`
- [x] T2.3 Selection highlighting
- [x] T3.1 Rival team and roster editor, "+" tile for unknown numbers
- [x] T3.2 Session setup
- [x] T3.3 Shot entry end to end
- [x] T3.4 Shot log with undo/delete
- [x] T4.1 `StatsEngine` and tests
- [x] T4.2 Linked-view component
- [x] T4.3 Shooter card
- [x] T4.4 Rival goalkeeper card
- [x] T4.5 Reject taps inside the 6 m goal area
- [x] T5.0 Debug launch arguments (`-KPScreen`, `-KPData`)
- [x] T5.1 `InsightWriter` protocol, template fallback and tests
- [x] T5.2 `FoundationModelsInsightWriter` with availability check
- [x] T5.3 Shareable report card
- [x] T6.1 Bug fixing, iPad/iPhone polish, accessibility pass (with T6.1-A accessible drawn regions, T6.1-B linked goal/court layout, T6.1a visual identity)
- [x] T6.2 README
- [x] T6.3 Final commit, hackathon tag and submission
- [x] T6.5 Height × outcome and side × outcome charts
- [x] T6.6 Scouting patterns
- [x] T6.7 Miss sub-zones and one-piece miss highlight
- [x] T6.8 Shot-direction arrows on the court
- [x] T6.9 Spanish localization with a String Catalog (`es`, `es-419`)
- [x] T6.10 Penalty (7 m) card
- [x] T6.11 Match and club scopes
- [x] T7.1 Quick colour and leftover fixes
- [x] T7.2 Shot entry ergonomics — `565ef75`
- [x] T7.3 Empty, confirmation and data states — `ac0ba84`
- [x] T7.4 Dynamic Type and VoiceOver — `71198c1`, pushed with PR #17 · verify run5/run6 pass · Codex review (one P2 fixed in `b0297b1`)
- [x] T7.5-baseline Side-switch error clearing — `e8a8cd2`
- [x] T7.7 Navigation structure — `14fdef3`

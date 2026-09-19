# Keepercent — task tracking

Feature document: [docs/mvp.md](../../docs/mvp.md) · Deadline: **Friday Sep 25, 2026**
TDD: strict mode enabled for the Domain layer (RED → GREEN → REFACTOR), Swift Testing.

## Day 0 — Sat Sep 19 (setup)

- [x] T0.1 MVP definition written (`docs/mvp.md`) — inline
- [x] T0.2 Repository scaffolding: `.gitignore`, `README.md`, `CLAUDE.md`, task file — inline
- [ ] T0.3 Install Xcode 26 (blocker, several GB)
- [ ] T0.4 Create the Xcode project `Keepercent` (SwiftUI, iOS 26, universal)
- [x] T0.5 First commit + GitHub repository — https://github.com/tomioliveres/keepercent (public)
- [ ] T0.6 Daily update posted in `#daily-updates`

## Day 1 — Sun Sep 20 (domain)

- [ ] T1.1 `GoalTarget`: 3×3 inside grid, post segments, out directions + tests
- [ ] T1.2 `CourtZone`: polar derivation (5 sectors × 2 depths) + 7m + tests
- [ ] T1.3 `ShotClassification`: cross-shot vs near-post, height + tests
- [ ] T1.4 SwiftData models + mapping to domain values (primitive codes)
- [ ] T1.5 Demo data seed

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

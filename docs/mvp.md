# Keepercent — MVP Definition

> *Keepercent* = keeper + percent: a goalkeeper's shots turned into percentages.

> ACoding Hackathon 2026 · Solo developer · Official deadline: Sep 27, 2026, 23:00 CET via GitHub repository.
> **Personal deadline: Friday Sep 25** (no availability on Sep 26–27). Everything ships on Friday.

## 1. Problem

Amateur handball goalkeepers scout rival teams to anticipate where each shooter tends to shoot, and to tell their own teammates where the rival goalkeeper is weakest. Today this is done with generic stats apps (e.g. Steazzi) or by memory. Existing tools miss goalkeeper-level detail, such as *which* post or crossbar segment a shot hit.

## 2. Product Vision

A native iPad-first (universal) app that lets a goalkeeper **record shots in seconds** — live from the bench or calmly from a video — and turns them into **actionable scouting**:

- **How rival shooters shoot**: where from, where to, and how it ended.
- **Where the rival goalkeeper is weak**: save rate by goal zone, per goalkeeper.
- **What to tell the team**: a shareable report card.

## 3. Hackathon Constraints (non-negotiable)

- Swift + SwiftUI, 100% native. Zero third-party code in the app binary.
- **Minimum OS version 26** (iOS / iPadOS). The organizers confirmed on Sep 19 that 26 is the floor and building against a newer SDK is allowed, so the project is built with Xcode 27 and a deployment target of iOS 26.
- Built from scratch during the event.
- Free Apple account: **no CloudKit, no Push Notifications, no Siri capability**. HealthKit, Maps, Background Modes, and App Groups are available.
- Every line must be explainable to the jury.
- Judging criteria: functionality · code quality · creativity · correct use of native Apple APIs.

## 4. Users and Modes

Single user: the goalkeeper (or whoever is scouting). Data lives on the device.

There is **one shot entry flow**. A session is tagged by its context:

| Session kind | When | Usage |
|---|---|---|
| **Live** | During the match, from the bench | Speed: 3–4 taps per shot, large targets, undo |
| **Video** | Before the match, watching a rival video on another screen (e.g. a computer) and pausing | Same flow, more time to fill the optional details |

The app does **not** play video. The kind is just metadata. All sessions write to the **same rival profile**, so knowledge accumulates.

## 5. Domain Model

```
RivalTeam
 └─ Player (number, name?, isGoalkeeper, handedness?)

Session (date, kind: live | video, opponent: RivalTeam)
 └─ Shot
     ├─ attackingSide    rival | own
     ├─ shooter          Player?   (required when rival attacks; nil when own team attacks)
     ├─ facingGoalkeeper Player?   (rival goalkeeper; required when own team attacks)
     ├─ origin           normalized point (x, y ∈ 0...1), nil for 7m
     ├─ isSevenMeters    Bool      (auto-detected from the tap on the 7m mark)
     ├─ target           inside(row, col) | post(segment) | out(direction)
     ├─ outcome          goal | saved | post | out
     ├─ delivery         jump | standing | nil     (optional)
     └─ approach         fromLeft | fromRight | straight | nil (optional)
```

### 5.1 Goal target

**Perspective: the shooter's view** (facing the goal and the goalkeeper). Every "left/right" label in the app, for both the goal and the court, is from the shooter's point of view. The shooter's left is the goalkeeper's right. The court is drawn with the goal at the top, so origin and target share the same frame of reference.

- **Inside**: a 3×3 grid (top/middle/bottom × left/center/right).
- **Post**: left post (top/middle/bottom), crossbar (left/center/right), right post (top/middle/bottom).
- **Out**: wide left, wide right, over.

A tap on the frame or outside **fully resolves** the outcome (`post` / `out`). A tap inside asks one question: **goal or saved**.

### 5.2 Court origin

- Store the raw normalized tap point, and **derive** the zone from it (so zones can be redefined without data loss).
- **Normalized frame** (the contract between the view and the domain): `x` runs 0 → 1 from the shooter's left touchline to the shooter's right touchline across the 20 m court width; `y` runs 0 → 1 from the goal line to the far edge of the drawn area (15 m, deep enough for any real shot). Out-of-range taps are clamped rather than dropped, so a drag ending a pixel outside the canvas still records a shot.
- Zones (validated, based on the reference app): **5 radial sectors** fanning out from the goal (left wing, left back, center, right back, right wing) × **2 depths** split by the 9m dashed line (near: 6–9m, far: beyond 9m) = **10 zones**, plus the 7m mark. The pivot is "center, near".
- **Real court geometry** (the drawing must match what a handball player expects, and the zone math is derived from it): the goal is 3 m wide; the 6 m area and the 9 m line are NOT semicircles — each is two quarter circles centred on the goalposts joined by a straight segment parallel to the goal line; the 7 m mark is a short line 7 m from the goal line, centred.
- Zone derivation is pure geometry, and the **angle and the distance are measured from different references on purpose**:
  - **Sector** — the signed angle at the **goal centre**, measured from the axis running straight out of the goal, positive toward the shooter's right. The 180° half-plane is split evenly into 5 sectors of 36°, so the cuts fall at ±18° and ±54°. Those cuts land between the real playing positions: a wing at the corner of the 6 m area sits near 74°, a back near 29°, the centre near 0°. A boundary angle belongs to the more central sector.
  - **Depth** — the distance to the **goal mouth** (the 3 m segment between the posts), not to the goal centre. The 9 m line *is* the locus of points 9 m from that segment, which is exactly why it is drawn as two quarter circles joined by a straight segment. Measuring from the goal centre would give a circle instead, and a tap that clearly falls outside the drawn 9 m line near a post would be classified as near. The boundary (exactly 9 m) belongs to `near`.
  - Because the raw normalized point is what gets stored, both thresholds can be redefined later without losing a single recorded shot.
- Layout: **goal on top, court below, on the same screen**. Court tap and goal tap form one vertical path.
- A dedicated, clearly visible hit area on the **7m mark** sets `isSevenMeters = true` and skips the origin, with an undoable "7m ✓" chip.

### 5.3 Derived metrics (computed, never stored)

- **Cross-shot vs near-post**: compare the origin side with the target column. From the left side, a right-column target is a cross-shot and a left-column target is near-post. Center origins are neither.
- **Height distribution**: top / middle / bottom.
- **Effectiveness**: goals / total, per zone and per origin→target pair.
- **Goalkeeper save rate**: saved / on-target shots, per goal zone.

## 6. Core Screens (MVP)

1. **Rival teams**: list, create, and a roster editor (numbers, goalkeepers). Rosters are reused across sessions against the same rival. A "+" tile adds an unknown number **during** entry, without leaving the screen.
   - **Roster import (P1)**: photo or PDF of the official match sheet → Vision OCR → Foundation Models structures it into `[{number, name}]` → **mandatory review screen** before saving. PDF pages are rendered with PDFKit. Printed sheets (the usual case for video scouting) read well; handwritten ones are corrected in the review screen.
2. **Session setup**: rival and kind (live/video).
3. **Shot entry** (single flow for every session kind)
   - Attacking side toggle (rival / own).
   - Active rival goalkeeper, persistent at the top and inherited by own-team shots.
   - Shooter grid (rival numbers) → court tap → goal tap → goal/saved if needed.
   - Optional chips: jump/standing, approach.
   - **Mis-tap safety**: `impliedOutcome` saves a tap, it never means "saved and gone". Every recorded shot is echoed back as a card showing exactly what was stored (`#7 · left back · crossbar center · POST`) next to a large **Undo**, with haptic feedback on save. The shot log allows editing or deleting any earlier shot too, because a mistake is often noticed several plays later. Nothing is ever committed silently.
   - Undo of the last shot, always visible.
4. **Shooter card**: linked views. Selecting a court zone filters the goal heatmap to shots from that zone. Origin→target arrows, 7m shown separately, and insight text.
5. **Rival goalkeeper card**: the same linked-view component, read as save rate per zone (strong/weak), with 7m shown separately.
6. **Team report**: a visual card of "where to shoot / where not to", rendered with `ImageRenderer` and shared with `ShareLink` (e.g. to the team's WhatsApp group).

### 6.1 Reference analysis: Steazzi

Based on screenshots of the app the author already uses. They are kept in `reference/capturas-steazzi/`, which is gitignored: third-party content stays local and is never published. A second reference, statzpro.com (a paid handball stats SaaS for coaches), was reviewed too: it also records frame hits as a single "post" event and puts goalkeeper zone stats behind a paid plan, which confirms the differentiator.

| Decision | Item | Notes |
|---|---|---|
| **Take** | Three-column iPad landscape entry screen: roster · goal + court · context panel | On iPhone, stack vertically |
| **Take** | Roster as a grid of big numbered tiles, goalkeepers visually distinct | Selected shooter shown as a label under the court |
| **Take** | Selected court zone and goal zone highlighted | Instant visual confirmation |
| **Take** | Contextual outcome buttons appear only when needed | In our app, only for inside-the-frame taps |
| **Adapt** | Outside the goal is a single "missed shot" area | Split it into **post segments + wide left/right/over** (our differentiator) |
| **Adapt** | Selecting a goalkeeper switches the perspective | Replaced by the attacking-side toggle + active rival goalkeeper |
| **Adapt** | Scoreboard | Derived from recorded goals, no manual input (P1) |
| **Adapt** | Timeline | A simple shot log with undo/delete |
| **Discard** | Match clock and halves, sanctions, defense/attack events, area invasion, empty-goal events, bench/court substitutions, per-team arrow buttons (unknown purpose, never used) | Not needed for shot scouting |

## 7. Native Apple APIs (the "why native" story)

| Need | API |
|---|---|
| UI, adaptive iPad/iPhone | SwiftUI, `NavigationSplitView`, size classes |
| Persistence | SwiftData |
| Court and goal drawing and hit-testing | SwiftUI `Canvas` / `Shape` + gestures |
| Heatmaps and distributions | Swift Charts |
| Natural-language insights | Foundation Models (guided generation) |
| Match sheet OCR and PDF pages | Vision, PDFKit, `PhotosPicker` / camera |
| Sharing the report | `ImageRenderer`, `ShareLink` |
| Localization | String Catalogs (English + Spanish) |
| Tests | Swift Testing |

**Stretch goals** (only if the core is done): Live Activity with the live match score, a widget with the next rival, App Intents / Shortcuts.

## 8. Architecture

Feature-first ("screaming") folders, with a pure domain core:

```
App/
Domain/            ← pure Swift, no SwiftUI/SwiftData imports, fully unit-tested
  GoalTarget, CourtZone, ShotClassification, StatsEngine
Persistence/       ← SwiftData @Model types + mapping to domain values
Features/
  Teams/  Sessions/  ShotEntry/
  ShooterCard/  GoalkeeperCard/  Report/
Insights/          ← InsightWriter protocol
  FoundationModelsInsightWriter   (on-device LLM)
  TemplateInsightWriter           (deterministic fallback)
DesignSystem/      ← CourtView, GoalView, HeatmapCell, colors
```

Key decisions:

- **Numbers are computed by code; the LLM only phrases them.** `StatsEngine` produces deterministic, tested facts. `FoundationModelsInsightWriter` turns them into sentences, and never computes figures.
- **Graceful AI fallback**: check `SystemLanguageModel.default.availability`. If Apple Intelligence is unavailable, use `TemplateInsightWriter`.
- **Persist primitives, expose enums**: store the target as a simple code (e.g. `"inside.0.2"`, `"post.left.top"`) and the origin as two `Double`s. Map them to rich enums in the domain. This avoids SwiftData issues with enums that carry associated values, and keeps predicates simple.
- **One linked-view component** (court ↔ goal) reused by both cards.
- **Demo data seed**: a debug/demo action that loads a realistic sample rival, so the jury never opens an empty app.

## 9. Scope Priorities

| Priority | Item |
|---|---|
| **P0 — must ship** | Domain + persistence, rival roster, live shot entry, shooter card with linked views, rival goalkeeper card, demo data |
| **P1 — should ship** | Foundation Models insights (with fallback), shareable report, roster import from a match sheet (Vision + PDFKit + Foundation Models, with a review screen) |
| **P2 — stretch** | EN/ES localization, origin→target arrows |
| **P3 — only if far ahead** | Live Activity, widget, App Intents |

There is no in-app video player: video scouting is done by watching the video on another screen and using the normal shot entry flow.
| **Out of scope** | Multi-user sync, backend, own goalkeepers' stats, accounts |

## 10. Day-by-Day Plan

| Day | Date | Goal | Daily update |
|---|---|---|---|
| 0 | Sat 19 | This document, Xcode project, GitHub repository, README skeleton | post |
| 1 | Sun 20 | Domain model + classification (zones, targets, cross/near post) with tests; SwiftData models; demo data seed | post |
| 2 | Mon 21 | `CourtView` and `GoalView` components with precise hit-testing | post |
| 3 | Tue 22 | Live shot entry end-to-end: rival roster, session, attacking side, active rival goalkeeper, undo | post |
| 4 | Wed 23 | `StatsEngine` + reusable linked-view component → shooter card **and** rival goalkeeper card | post |
| 5 | Thu 24 | Foundation Models insights + template fallback, shareable report, roster import (Vision + PDFKit). **Feature freeze at the end of the day** | post |
| 6 | Fri 25 | Bug fixing, iPad/iPhone polish, accessibility pass, README, screenshots/GIF, **submit** | post (final) |
| — | Sat 26 – Sun 27 | Unavailable. Nothing planned | short "submitted" post if possible |

Rules for the compressed plan:

- **Thursday night is the feature freeze.** Friday is for stability and presentation only.
- P2 items enter only on a day whose P0/P1 goal finished early.
- If a day slips, cut from the bottom of the priority table, never from tests or the README.

## 11. Definition of Done (submission)

- Builds and runs on the iPad and iPhone simulators (iOS 26) with no warnings about third-party dependencies (there are none).
- Demo data loads in one tap.
- README: problem, features, screenshots/GIF, native APIs used, architecture, how to run, AI usage disclosure.
- Domain and stats logic covered by Swift Testing.
- The author can explain every file.

## 12. Risks

| Risk | Mitigation |
|---|---|
| Hit-testing on small goal-frame segments is imprecise | Enlarge the frame hit areas beyond the visual stroke; test on iPad early (Day 2) |
| Foundation Models unavailable on the jury's setup | Template fallback, always working |
| OCR quality on handwritten match sheets | Mandatory review screen; manual entry always available |
| Thursday holds three P1 items | Cut order: roster import → shareable report → insights. Insights are the AI story, so they ship first |
| SwiftData and enums with associated values | Persist primitive codes (see §8) |
| Scope creep | P0 first; P2 only after P0+P1 are done |

## 13. Open Questions

1. ~~Goal map perspective~~ → **Resolved: shooter's view** (§5.1).
2. ~~Court zones~~ → **Resolved: 5 radial sectors × 2 depths + 7m** (§5.2).
3. ~~Outcomes~~ → **Resolved: blocked shots are not recorded.** They say nothing about the goalkeeper or the shooter's target.
4. ~~App name~~ → **Resolved: Keepercent**.
5. ~~Submission logistics~~ → **Resolved**: the user can submit from a phone over the weekend if the link arrives late.

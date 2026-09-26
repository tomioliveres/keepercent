# Keepercent

> *keeper + percent* — a handball goalkeeper's scouting tool: rival shots turned into percentages.

**ACoding Hackathon 2026** · Solo project · 100% native Swift & SwiftUI, zero third-party dependencies.

## The problem

Amateur handball goalkeepers scout rival teams before every match: who shoots from where, towards which part of the goal, and how it ends. The existing tools are built for coaches keeping full match statistics. They record a shot that hits the frame as a single "post" event, and they hide goalkeeper analysis behind a paid plan.

A goalkeeper needs the detail those tools drop: *which* post, *which* part of the crossbar, and how the rival goalkeeper behaves, so the team knows where to shoot.

## What it does

- **Record shots** in live or video-tagged sessions: shooter, court origin, goal target, outcome, and optional context. Video plays on a separate screen.
- **Goal-frame detail**: left/right post (top, middle, bottom), crossbar (left, center, right), and misses by direction.
- **Shooter card**: court and goal heatmaps that filter each other. Pick a court zone, see where those shots went.
- **Rival goalkeeper card**: save rate per goal zone, so you can tell your teammates where to shoot.
- **Plain-language insights** from tested statistics, with an on-device model when available and a deterministic fallback otherwise.
- **Shareable rival goalkeeper report** rendered as an image from recorded shots.

## Status

Immediate hackathon MVP: teams and manual rosters, live/video session shot entry, a shot log with last-shot Undo, linked scouting cards, insights and image sharing are available.

Roster OCR/PDF import is deferred to a later version; its branch is not part of this MVP. Earlier shots can be deleted and re-recorded, not edited in place. T6.1 iPad/iPhone polish and accessibility testing remain open; this is not a claim of complete UI validation or App Store readiness. See [docs/mvp.md](docs/mvp.md) for the original scope and [the task ledger](odd/tasks/keepercent.md) for current status.

## Requirements

- Xcode 27; iOS/iPadOS 26 minimum
- No dependencies, no account, no backend. All data stays on the device.

Open `Keepercent.xcodeproj` in Xcode 27, select the shared `Keepercent` scheme and an iOS 26-or-newer iPhone or iPad simulator, then Run. The app opens on a seeded demo rival team. To run the pure Swift domain tests locally: `swift test --package-path Domain`.

## AI usage

Generative AI was used as a coding assistant during development, and Apple's on-device Foundation Models power the natural-language insights inside the app. All statistics are computed by tested, deterministic code; the model only phrases results it is given.

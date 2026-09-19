# Keepercent — project context

Handball goalkeeper scouting app built for the **ACoding Hackathon 2026** (Apple Coding Academy).
Product definition and plan: [docs/mvp.md](docs/mvp.md) · Task tracking: [odd/tasks/keepercent.md](odd/tasks/keepercent.md)

## Hard rules (from the hackathon, non-negotiable)

- **100% native**: Swift and SwiftUI only. **Zero third-party code inside the app binary** — no SPM packages, no frameworks, no vendored sources. UIKit/AppKit is allowed when a case truly needs it.
- Anything inside Apple's SDK counts as native: SwiftData, Swift Charts, Foundation Models, Vision, PDFKit, Core ML, AVFoundation…
- **Development tools are not bound by that rule** (a linter or formatter is fine); the restriction covers what ships in the binary.
- `URLSession` may call any API, but this app is offline by design.
- **Minimum OS version 26** (iOS / iPadOS). Confirmed by the organizers: 26 is the floor, a newer SDK is allowed. Built with Xcode 27, deployment target iOS 26.
- Built **from scratch** during the event (Sep 18–27, 2026). No prior code.
- **Free Apple account**: no CloudKit, no Push Notifications, no Siri capability. HealthKit, MapKit, Background Modes and App Groups are available.
- Generative AI may be used to write code, but **every line must be explainable by the author**. Do not introduce code the author cannot defend.
- Delivery is a public GitHub repository. No App Store submission.

## Where things are

- `Domain/` — pure Swift package, no dependencies, fully tested.
- `docs/mvp.md` — product definition, scope and plan. `docs/bitacora.html` — the Spanish study log, updated at the end of each day.
- `odd/tasks/keepercent.md` — task checklist.
- `reference/` — **gitignored, local only**: hackathon rules PDF, Discord briefings and screenshots of the reference app (third-party material that must never be published).

## Judging criteria

Functionality · code quality and cleanliness · creativity · correct use of native Apple APIs.

## Deadlines

- Personal deadline: **Friday Sep 25, 2026** (no availability on the weekend).
- Official deadline: Sep 27, 2026, 23:00 CET.
- A daily progress update must be posted in the hackathon's `#daily-updates` channel before 23:00 CET.

## Engineering conventions

- **Domain layer is pure Swift**: no SwiftUI or SwiftData imports, fully unit-tested with Swift Testing. TDD: RED → GREEN → REFACTOR.
- **Statistics are computed by deterministic, tested code.** Foundation Models only phrases facts it is given; it never computes numbers.
- Every AI-powered feature has a working non-AI fallback (`SystemLanguageModel.default.availability` is checked).
- Persist primitive values (codes, doubles); expose rich enums in the domain.
- Feature-first folder structure. Reuse one linked-view component for both the shooter and the goalkeeper cards.
- Conventional Commits. Code, comments, UI copy and documentation in English.

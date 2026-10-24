# Keepercent — project context

Handball goalkeeper scouting app. Started for the **ACoding Hackathon 2026** (Apple Coding Academy); the hackathon ended on Sep 27, 2026 and was delivered. Since then it is a **personal project** with no deadlines.
Product definition and plan: [docs/mvp.md](docs/mvp.md) · Task tracking: [odd/tasks/keepercent.md](odd/tasks/keepercent.md)

## Hard rules (inherited from the hackathon, kept by choice)

- **Swift and SwiftUI**, native-first. UIKit/AppKit is allowed when a case truly needs it.
- **Third-party code is allowed since 2026-10-19.** The former "100% native, zero third-party code in the binary" rule was a hackathon requirement and no longer applies. Prefer Apple's SDK (SwiftData, Swift Charts, Foundation Models, Vision, PDFKit, Core ML, AVFoundation…) when it solves the problem well; add an SPM package only when it is clearly better, and record why in the task file.
- `URLSession` may call any API, but this app is offline by design.
- **Minimum OS version 26** (iOS / iPadOS). Confirmed by the organizers: 26 is the floor, a newer SDK is allowed. Built with Xcode 27, deployment target iOS 26.
- Built **from scratch** starting at the event (Sep 18–27, 2026). No prior code.
- **Free Apple account**: no CloudKit, no Push Notifications, no Siri capability. HealthKit, MapKit, Background Modes and App Groups are available.
- Generative AI may be used to write code, but **every line must be explainable by the author**. Do not introduce code the author cannot defend.
- The code lives in a public GitHub repository. No App Store submission.

## Where things are

- `Domain/` — pure Swift package, no dependencies, fully tested.
- `docs/mvp.md` — product definition, scope and plan. `docs/index.html` — the Spanish study log, updated at the end of each day and served at https://tomioliveres.github.io/keepercent/ through GitHub Pages (branch `main`, folder `/docs`). It is ONE incremental page: update it in place, never create a document per day. The repository file is the single source of truth; a push publishes it.
- `odd/tasks/keepercent.md` — task checklist.
- `reference/` — **gitignored, local only**: hackathon rules PDF, Discord briefings and screenshots of the reference app (third-party material that must never be published).

## Quality bar

Functionality · code quality and cleanliness · creativity · correct use of native Apple APIs (the former judging criteria, kept as the project's own standard).

## Pace

- No deadlines and no daily progress posts. Prioritize what the author will use or enjoy.
- Keep process proportional: weigh the cost of verification rounds and review ceremony against the value of the task.
- One review per task, at task close; accept scoped functional test outcomes without demanding assertion-by-assertion evidence. Record incomplete verification and accepted debt explicitly.
- **Lightweight process profile (since 2026-10-23)**: receipt-driven review (`gentle-ai review`) is disabled for this clone; the ledger holds one line per task; Engram does not mirror versioned files (git is the source of truth) and keeps decisions only.

## Engineering conventions

- **Domain layer is pure Swift**: no SwiftUI or SwiftData imports, fully unit-tested with Swift Testing. TDD: RED → GREEN → REFACTOR.
- **Statistics are computed by deterministic, tested code.** Foundation Models only phrases facts it is given; it never computes numbers.
- Every AI-powered feature has a working non-AI fallback (`SystemLanguageModel.default.availability` is checked).
- Persist primitive values (codes, doubles); expose rich enums in the domain.
- Feature-first folder structure. Reuse one linked-view component for both the shooter and the goalkeeper cards.
- **Container / presentational views**: `@Query` is confined to container views; presentational views only draw domain structs they receive, never touch SwiftData directly.
- **`StatsEngine` never receives a `ModelContext`**: it takes domain structs, so every statistic stays testable without a simulator.
- **Testing policy**: TDD is strict on `Domain/` (`swift test`, RED → GREEN → REFACTOR); views are verified by UI tests, snapshot tests (once introduced) and simulator screenshots. `Tools/Overnight/check.sh` is the single gate: Domain tests plus the app and UI-test run on a simulator.
- **One review per task, at close**: when a task touches `Domain/` or `Keepercent/Persistence/`, run `codex exec -s read-only` over `git diff <task base>...HEAD` before closing; visual-only tasks rely on the gate and simulator checks. Fix confirmed defects in the same task branch.
- **Closure lives in the task branch**: the last commit of `task/<id>` (or `auto/<id>`) checks the task off with its commits, checks, verification and review. Docs not tied to a task (study log, `docs/mvp.md`) may go straight to `main` as `docs:` commits.
- Conventional Commits. Code, comments, UI copy and documentation in English.

## Workflow (everything in Claude Code, since 2026-10-23)

- **One task at a time.** OpenCode and the cross-runtime handoff are retired.
- **`/auto-task`** (`.claude/skills/auto-task/SKILL.md`) implements, tests, self-verifies in the simulator, fixes, reviews and closes one task end to end without asking. It runs interactively or unattended.
- **Unattended runs**: `Tools/Overnight/run.sh` (see [docs/overnight.md](docs/overnight.md)) chains the tasks marked `auto` in [odd/overnight/queue.md](odd/overnight/queue.md) on an integration branch `overnight/<date>`, in its own worktree and simulator, and pushes that branch after each finished task. It never touches `main`: the author reviews the run report and fast-forwards `main` in the morning.
- **Model self-verification is not author verification.** Screenshots judged by the model are recorded as `self-verified`; `/verify-ui` remains available for an independent exact-SHA check when the author wants one. A missing visual capability yields `unverifiable`, not `pass`.
- Tasks that need the author's judgement (usability sessions, publishing, new visual direction, product decisions) are never marked `auto`.

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
- One review per task slice unless native assessment is high; accept scoped functional test outcomes without demanding assertion-by-assertion evidence. Record incomplete verification and accepted debt explicitly.

## Engineering conventions

- **Domain layer is pure Swift**: no SwiftUI or SwiftData imports, fully unit-tested with Swift Testing. TDD: RED → GREEN → REFACTOR.
- **Statistics are computed by deterministic, tested code.** Foundation Models only phrases facts it is given; it never computes numbers.
- Every AI-powered feature has a working non-AI fallback (`SystemLanguageModel.default.availability` is checked).
- Persist primitive values (codes, doubles); expose rich enums in the domain.
- Feature-first folder structure. Reuse one linked-view component for both the shooter and the goalkeeper cards.
- **Container / presentational views**: `@Query` is confined to container views; presentational views only draw domain structs they receive, never touch SwiftData directly.
- **`StatsEngine` never receives a `ModelContext`**: it takes domain structs, so every statistic stays testable without a simulator.
- **Testing policy**: TDD is strict on `Domain/` (`swift test`, RED → GREEN → REFACTOR); views are verified visually, not unit-tested.
- **Review one slice per task, not one per commit**: after a work-unit commit run `gentle-ai review assess --base-ref <last reviewed boundary> --committed-only --json` and record the tier. On **medium**, let the slice accumulate and open the review once, at task close, from that same boundary. Always pass `--base-ref` explicitly: without it the preflight re-drags already-acknowledged work into the candidate, and on a clean tree it refuses outright. Risk is decided by the assessment, never by judgement. The candidate is a PR slice or a work-unit commit, never a TODO checkbox.
- **Once a review is acknowledged, the tree freezes until the next task starts**: the candidate's identity follows the working tree, so every commit after an acknowledgement buys another blocking prompt for work the assessor itself reports as `under_budget`. Task N's review outcome is written as the first commit of task N+1, and that review's advisory findings are applied there too — never as a follow-up commit on the just-acknowledged tree.
- Conventional Commits. Code, comments, UI copy and documentation in English.

## Workflow split (OpenCode ↔ simulator verifier)

- **One task at a time.**
- **OpenCode writes code**: `/next-task` (`.claude/skills/next-task/SKILL.md`) implements with TDD, runs `swift test`, builds, commits, reviews and closes. It never boots a simulator.
- **Simulator verification has two adapters** sharing the installed `verify-interface` policy and [Keepercent profile](docs/ui-verification.md): Claude Code `/verify-ui` (`.claude/skills/verify-ui/SKILL.md`) supplies its Simulator MCP route; Codex desktop loads `verify-ios-simulator` and selects structured tools plus Computer Use by capability. Both use the isolated exact-SHA target and shared case ledger. The Claude-only adapter does not apply to Codex; its model selection is not global policy.
- The handoff lives in `$(git rev-parse --git-common-dir)/handoff/<task-id>.md` (inside `.git/`, never committed), mirrored to Engram `keepercent/verify/<task-id>`.
- Codex must explicitly read this local `CLAUDE.md` (it is not automatically loaded), use the handoff in the shared Git common directory, and write `updated: <ISO date> by codex` only when it can write the authoritative handoff. If it cannot write it, report the evidence to OpenCode without claiming a passing handoff. A missing visual capability yields `unverifiable`, not `pass`.
- UI verification happens **before** the RDD review, so a fix never lands on an acknowledged tree.

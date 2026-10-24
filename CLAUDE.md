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
- **Testing policy**: TDD is strict on `Domain/` (`swift test`, RED → GREEN → REFACTOR); views are covered by permanent UI flow tests, accessibility audits and snapshot tests (once introduced), plus simulator screenshots. Tests are regression suites that run on every task, never one-off checks.
- **`Tools/check.sh` is the single gate for every workflow**: `--build-only` (Domain tests, app build, UI-test compilation; no simulator) while implementing, and `--simulator <udid>` (every Domain and UI test) before a task closes. A task closes only with the full gate green or with each remaining failure recorded as expected with its cause.
- **One review per task, at close**: when a task touches `Domain/` or `Keepercent/Persistence/`, run `codex exec -s read-only` over `git diff <task base>...HEAD` before closing; visual-only tasks rely on the gate and simulator checks. Fix confirmed defects in the same task branch.
- **Closure lives in the task branch**: the last commit of `task/<id>` (or `auto/<id>`) checks the task off with its commits, checks, verification and review. Docs not tied to a task (study log, `docs/mvp.md`) may go straight to `main` as `docs:` commits.
- Conventional Commits. Code, comments, UI copy and documentation in English.

## Workflows (pick one per task)

**One task at a time**, whatever the workflow. All three share the same conventions: a task branch from `main`, strict TDD in `Domain/`, the `Tools/check.sh` gate, closure in the task branch, and the review rule above.

| Workflow | When | How |
| --- | --- | --- |
| **A. Step by step (OpenCode + Claude Code)** | The author is present, wants to go one step at a time, or the task needs their judgement. Uses both runtimes' models. | OpenCode `/next-task` implements and gates with `--build-only`; Claude Code `/verify-ui` runs the full gate and the exact-SHA visual check; OpenCode closes. |
| **B. One task end to end (Claude Code)** | The author is around but does not want to relay between runtimes. | Claude Code `/auto-task <task-id>` implements, runs the full gate, self-verifies in the simulator, fixes, reviews and closes without asking. |
| **C. Unattended chain (overnight)** | The author is away and has spare quota. | `Tools/Overnight/run.sh` runs workflow B for each task marked `auto` in [odd/overnight/queue.md](odd/overnight/queue.md) on `overnight/<date>`; see [docs/overnight.md](docs/overnight.md). |

### Workflow A details

- **Route by size**: quick, mostly visual or copy changes (and small defects reported by `/verify-ui`) may be done directly in a Claude Code Sonnet session on the task branch; Domain logic, data and persistence, navigation or structural changes and multi-step features go to OpenCode `/next-task` (`.claude/skills/next-task/SKILL.md`). OpenCode never boots a simulator.
- **Defect fixes from a verdict**: the author picks where they are fixed. A quick fix in Claude Code commits on the task's branch and sets the handoff back to `ready` with the new `sha`; `/verify-ui` re-checks only the affected cases; OpenCode then closes the task.
- **Simulator verification runs only in Claude Code**: `/verify-ui` (`.claude/skills/verify-ui/SKILL.md`) follows the [Keepercent profile](docs/ui-verification.md), works on the isolated exact-SHA checkout `../keepercent-verify`, and never edits source, commits, merges or pushes.
- The handoff lives in `$(git rev-parse --git-common-dir)/handoff/<task-id>.md` (inside `.git/`, never committed). A missing visual capability yields `unverifiable`, not `pass`.
- UI verification happens **before** review.

### Workflows B and C details

- **Model self-verification is not author verification.** Screenshots judged by the model are recorded as `self-verified`; the author can still run `/verify-ui` for an independent exact-SHA check.
- Workflow C never touches `main`: it pushes only `overnight/<date>`, and the author reviews the run report and fast-forwards `main`.
- Tasks that need the author's judgement (usability sessions, publishing, new visual direction, product decisions, real stores) are never marked `auto`; run them with workflow A.

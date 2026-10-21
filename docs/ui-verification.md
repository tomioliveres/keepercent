# Keepercent UI verification profile

Use the installed `verify-interface` skill for shared evidence and recovery rules, then `verify-ios-simulator` for iOS mechanics. Both are installed under `${CODEX_HOME:-$HOME/.codex}/skills/<name>/SKILL.md`; Claude Code reads them from there. If they are unavailable, report the missing policy rather than silently using a weaker contract.

## Target and safe state

- Read the main checkout's `CLAUDE.md`. Select an explicit task first, otherwise the unique applicable handoff; ask on ambiguity.
- Resolve the shared handoff from `git rev-parse --path-format=absolute --git-common-dir`, then `handoff/<task-id>.md`. Its full `sha`, screens, and checks are authoritative.
- Use the existing detached `../keepercent-verify` checkout for that exact SHA. Confirm it is clean, is not in use by another verifier, and is a worktree of this repository before changing its revision. Never reset or discard unrelated work. Recheck task/SHA before and after recording results.
- Project: `Keepercent.xcodeproj`; scheme: `Keepercent`; app identifier: `dev.tomioliveres.keepercent`. Select available iOS/iPadOS 26+ targets; do not install runtimes.
- Use `-KPScreen <screen> -KPData <demo|empty>` only when supported by the target commit. These launch flags are not proof of an isolated store: confirm the selected route uses disposable/in-memory data before interacting. Never erase or overwrite a personal store to prepare cases.
- For T77-ORPHAN, use `-KPScreen teams -KPData orphanSession` on a supporting target. This Debug-only fixture inserts one live session at `DemoData.sessionDate`, with no rival and zero shots, into the argument-mode in-memory store; it never deletes a rival or opens a personal store. Matches should show Deleted Rival, the date/kind/zero-shot count and the unavailable-entry explanation. Tapping the row must not open shot entry. Relaunching recreates the fixture; Rivals and My Club are empty. Existing `demo`, `empty`, `demoOwnRoster` and `emptyGoalkeeper` modes are unchanged.

## Runtime adapters

| Runtime | Execution route |
| --- | --- |
| Claude Code (the only verifier since 2026-10-19) | `.claude/skills/verify-ui/SKILL.md` supplies its Simulator MCP adapter and observed tool workarounds. It must also load the shared policy and this profile. |
| OpenCode | Prepare the handoff and consume the verdict with `/next-task`; do not boot Simulator. |

For the shell route, build inside the isolated checkout with `xcodebuild -project Keepercent.xcodeproj -scheme Keepercent -destination 'platform=iOS Simulator,name=<available device>' -derivedDataPath build/DerivedData build`, then install/launch that artifact through the chosen authorized adapter. Do not rebuild merely to switch interaction tools.

## Case scope and evidence

- Preserve every requested handoff check. On initial/full verification, use iPhone then iPad, light/dark, and applicable demo/empty states. Standard project checks: sensible empty states, visible tappable-zone tint, no sheet/alert interference, readable dark-mode text, and no iPhone clipping.
- On resumption, derive only affected and pending cases using the shared reuse rules. A narrower user-authorized scope stays explicitly partial relative to the full project matrix. Never turn omitted cases into passes.
- Save evidence under `build/shots/<task-id>/<sha>/<run-id>/` in the verification checkout; keep prior runs intact. Record stable case IDs, actual backends, setup, screenshots, results, and reuse provenance in `## Verdict` using the shared ledger.
- Inspect exported files at full size and confirm the share attachment matches the displayed content when export is in scope. A share-sheet thumbnail is not file-content proof. Screenshots do not establish spoken VoiceOver behavior.
- A build/install success with no readable Simulator display is `unverifiable`. Diagnose once, try at most one permitted alternate capability path, then report blocked case IDs and the minimum next step; do not repeat the same failed controller per case.

## Handoff compatibility and ownership

Keep `task`, `status`, `sha`, `branch`, `updated`, `## Screens`, `## Checks`, and `## Verdict`. Add the ledger under `## Verdict`; no mandatory new top-level fields. Legacy handoffs without per-case evidence are valid inputs but cannot justify incremental skipping.

Only an explicitly requested verifier may update `status: pass | defects | unverifiable`, `updated: <ISO date> by <actual actor>`, and `## Verdict`. Preserve the original checks and historical verdicts. Read back target and written result; mirror best effort to `keepercent/verify/<task-id>`. If the authoritative file cannot be written/read back, return the report without claiming a passing handoff.

UI verification precedes native review. Defects return to the implementer; this profile never authorizes source edits, task closure, commits, merge, push, or permission changes.

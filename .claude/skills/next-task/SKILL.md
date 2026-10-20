---
name: next-task
description: "Trigger: /next-task, next task. Implement or resume one Keepercent task in OpenCode, then hand off UI verification before review and closure."
license: Apache-2.0
metadata:
  author: tomasoliveres
  version: "1.1"
---

# Next task (implementation side, OpenCode)

Reply to the user in Spanish. Artifacts (code, commits, task file) stay in English.
Project rules in `CLAUDE.md` win over anything here.

**Split of work**: this runtime writes code, runs `swift test`, builds, commits and reviews. It **never boots a simulator**. UI verification follows `docs/ui-verification.md`, the project profile for the installed `verify-interface` policy: verification runs only in Claude Code with `/verify-ui`, on the detached exact-SHA checkout and the authoritative handoff. If running in Claude Code, ask whether to continue here, then stop.

**One task at a time.** Never start a second task while one is open.

## Handoff file (source of truth between runtimes)

`$(git rev-parse --git-common-dir)/handoff/<task-id>.md` — inside `.git/`, so it is shared by every worktree and never enters a commit or a review candidate. Format:

```
task: T5.0
status: ready | pass | defects | unverifiable
sha: <full 40-char sha to verify>
branch: <branch>
updated: <ISO date> by <opencode|claude-code>
## Screens
- <-KPScreen value or navigation path> · <-KPData demo|empty>
## Checks
- <one observable acceptance check per line>
## Verdict
<written by the verifier: pass, numbered defects with screenshot paths, or unverifiable with reasons and unexercised checks>
```

The verifier records stable case IDs, setup, actual tools, screenshot evidence, and executed/carried-forward provenance under `## Verdict` using the shared ledger. Keep legacy fields unchanged; old handoffs without this evidence cannot justify skipping cases. Preserve prior verdicts when setting a new SHA ready for retest.

Mirror each status change to Engram topic `keepercent/verify/<task-id>` (best effort: if the save fails because of concurrent sessions, use the `engram` CLI; if that fails too, keep going — the file is authoritative).

## 0. Resume first

List the handoff directory. If a task has an open handoff, continue it instead of starting a new one:
- `ready` → tell the user to run `/verify-ui` in Claude Code for the same task; stop. Do not launch another task.
- `defects` → go to step 3.
- `pass` → go to step 4. `unverifiable` → report missing evidence and stop; ask the user how to proceed rather than treating it as a pass.

**No handoff is not proof of a fresh start.** Before selecting, check the first unchecked task for a half-closed run: its commits already on `main` (`git branch --contains <sha>`, or the task record names them), or Engram `keepercent/verify/<task-id>` reporting `pass`. If so the task is **mid-closure**: never reimplement it, and resume at step 4, doing only what is missing (assess/review, merge, check-off). Say so to the user in one line.

## 1. Select

Read `odd/tasks/keepercent.md` and the Engram mirror `odd/keepercent/tasks`; reconcile. Pick the **first unchecked, unblocked task** in file order. Say in one line which task and which files you expect to touch.

## 2. Implement

- Branch `task/<task-id>` from `main` (a worktree is optional; one task means the main checkout is fine).
- Strict TDD in `Domain/` with `cd Domain && swift test`: observe RED, then GREEN, then REFACTOR. Views are not unit-tested.
- Build the app (no simulator launch): `xcodebuild -project Keepercent.xcodeproj -scheme Keepercent -destination 'generic/platform=iOS Simulator' build`.
- Work-unit commits, Conventional Commits.
- Does the task change anything visible? **No** → skip to step 4. **Yes** → write the handoff with `status: ready`, the exact `sha` (`git rev-parse HEAD`), the screens to open and the checks, then tell the user to run Claude Code `/verify-ui <task-id>`, and **stop**.

## 3. Fix defects (one round)

Read the verdict, fix each numbered defect, run `swift test` and the build, commit, set `status: ready` with the new `sha`, and send the user back to `/verify-ui`. If the second verdict still has defects, stop and ask the user whether to accept, fix again, or cut scope. Never loop on your own. If the verifier could not update the handoff, inspect its returned report and evidence but do not treat the handoff as `pass`; reconcile verification explicitly before review or closure.

## 4. Review and close

Verification happens **before** review, so no fix commit ever lands on an acknowledged tree.

1. `gentle-ai review assess --cwd <repo> --agent opencode --base-ref <last reviewed boundary> --committed-only --json` and follow `CLAUDE.md` (passive → no review; medium/high → relay the consent envelope; never answer consent for the user).
2. Merge `task/<task-id>` into `main`, run `swift test` and the build once more. Remove the worktree if one was used.
3. Check the task off in `odd/tasks/keepercent.md` with commit SHAs, review tier and verification verdict; update the Engram mirror. Delete the handoff file **last**, only after the check-off is written, so an interrupted close never leaves a merged task that looks unstarted.
4. Report: task · commits · tests · verification · review. No push unless the user asks.

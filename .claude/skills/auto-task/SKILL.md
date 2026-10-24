---
name: auto-task
description: "Trigger: /auto-task, overnight, autonomous task. Implement, test, self-verify, fix, review and close one queued Keepercent task end to end in Claude Code without asking."
license: Apache-2.0
metadata:
  author: tomasoliveres
  version: "1.0"
---

# Auto task (one task, end to end, no questions)

Project rules in `CLAUDE.md` win over anything here. Replies to the author are in Spanish; code, commits and task files stay in English.

**Never ask.** This skill often runs unattended (`Tools/Overnight/run.sh`). When something truly needs the author (an open product or design decision, missing information, a capability that is unavailable), record it and finish as `blocked`. Do not guess product decisions.

## Inputs

The driver exports these; when run interactively, derive them as noted.

| Variable | Meaning | Interactive default |
| --- | --- | --- |
| `KP_TASK` | Task ID to run (or the skill argument) | First `- [ ]` entry tagged `auto` in `odd/overnight/queue.md` |
| `KP_BASE` | Branch the task starts from | Current branch |
| `KP_RUN_DIR` | Evidence and result directory (absolute, inside `build/`) | `build/overnight/manual/<task>` |
| `KP_SIMULATOR` | UDID of the dedicated simulator | Ask `xcrun simctl list devices available`; prefer a shut-down iPhone |

## Hard limits

- Work only in the current worktree, on branch `auto/<task>` created from `KP_BASE`. Never check out, merge into or push `main` or any other branch; never run `git push`, `gh`, `git reset --hard`, `git clean`, or `git worktree` commands. The driver merges and pushes.
- Use only `KP_SIMULATOR`. Never erase or delete a simulator, never open a personal store; launch with `-KPScreen <screen> -KPData <mode>` in-memory fixtures only.
- Never delete, weaken or blanket-skip a test to get green. `XCTExpectFailure`/`.disabled` is allowed only when the queue entry allows it, with a written reason in the test and in the result.
- Add an SPM dependency only when the queue entry authorizes it, and record why in the task notes.
- No `gentle-ai review` commands, no Engram mirrors of task files, no handoff files.

## 1. Prepare

1. Read `CLAUDE.md`, the queue entry for `KP_TASK` in `odd/overnight/queue.md`, the matching ledger line in `odd/tasks/keepercent.md` and any feature document or design decisions it links. The queue entry's **Acceptance** list is the definition of done.
2. `git switch -c auto/<task> "$KP_BASE"` (if the branch exists from a previous failed attempt, start fresh from `KP_BASE` with a new suffix `auto/<task>-2`, never reuse it). Record the base SHA.
3. `mkdir -p "$KP_RUN_DIR"`.

## 2. Implement

- `Domain/` changes: strict TDD with `swift test --package-path Domain` (observe RED, then GREEN, then refactor).
- Views: keep the container/presentational split; new launch fixtures go through `DebugLaunchConfiguration` with Domain tests.
- Commit in work units with Conventional Commits, tests and docs together.

## 3. Gate

Run `Tools/Overnight/check.sh "$KP_SIMULATOR" "$KP_RUN_DIR"`. It runs Domain tests, then builds and runs the app's UI tests on the simulator, and prints a short summary plus the log paths. Read the `.log` tails and the `xcresult` summary it prints for failures; do not paste whole logs.

## 4. Self-verify visible changes

Skip when the task changes nothing visible. Otherwise, for each screen the task touches:

1. Install the gate's built app (`build/DerivedData/Build/Products/Debug-iphonesimulator/Keepercent.app`) with `xcrun simctl install "$KP_SIMULATOR" <app>`.
2. For each combination of appearance (`xcrun simctl ui "$KP_SIMULATOR" appearance light|dark`) and text size (`xcrun simctl ui "$KP_SIMULATOR" content_size large` and `accessibility-extra-extra-extra-large`): launch with `xcrun simctl launch --terminate-running-process "$KP_SIMULATOR" dev.tomioliveres.keepercent -KPScreen <screen> -KPData <demo|empty|…>`, wait until rendered (about 15 s on first launch, 3 s after), and capture `xcrun simctl io "$KP_SIMULATOR" screenshot "$KP_RUN_DIR/<case>.png"`.
3. Read every screenshot and judge it against the acceptance list and the standard checks: sensible empty states, visibly tinted tappable zones, readable dark-mode text, nothing clipped or overlapping, no truncated identifiers at the largest text size.
4. Reset the simulator to `light` and `large` when done. Record each case as `pass`, `defect` (what, where, screenshot) or `unverifiable`.

## 5. Fix

Fix every gate failure and visual defect, then rerun the gate (and the affected visual cases). **At most three fix rounds in total.** If it is still red after the third round, finish as `failed` with the remaining failures.

## 6. Review

When the diff touches `Domain/` or `Keepercent/Persistence/`, run:

```bash
codex exec -s read-only "Review git diff <base-sha>...HEAD in this repository for correctness bugs, data loss and test gaps. Report only concrete, reproducible defects with file:line." > "$KP_RUN_DIR/review.md" 2>&1
```

Verify each reported defect against the code before acting on it. Fix confirmed defects within the remaining fix rounds and rerun the gate. If `codex` is unavailable, record `review: unavailable` and continue.

## 7. Close

1. In one final commit (`docs(tasks): close <task> …`): tick the task in `odd/overnight/queue.md` and in `odd/tasks/keepercent.md` (add the ledger line if the task is new), each as one line: commits, gate result, visual verdict (`self-verified`, not author-verified), review result, and accepted debt.
2. Write `$KP_RUN_DIR/result` with exactly two lines: the status (`done`, `blocked` or `failed`) and a one-sentence reason. Then write `$KP_RUN_DIR/report.md`: what changed, checks with observed results, screenshots list, open questions for the author.
3. Finish with a short Spanish summary for the author: task, status, commits, gate, visual verdict, review, and anything that needs them.

`done` requires: gate green, every acceptance item met, visual cases without open defects (or explicitly `unverifiable` with a reason), and the close commit made. For `blocked` or `failed`, leave the commits on `auto/<task>` without the close commit and explain in the report.

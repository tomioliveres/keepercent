# Unattended runs

`Tools/Overnight/run.sh` lets Claude Code work through queued tasks while the author is away. Each task runs `/auto-task` in a fresh headless session: implement, gate, self-verify in the simulator, fix (three rounds at most), review, close.

## Before the first run

1. Receipt-driven review must be off for this clone: `gentle-ai review mode disable --scope clone`.
2. `main` must contain the tasks to run (`odd/overnight/queue.md`, ledger lines) and this tooling.
3. `codex` should be logged in; without it, reviews are recorded as unavailable.
4. Check the plan: `Tools/Overnight/run.sh --dry-run`.

## Running

```bash
Tools/Overnight/run.sh --max-tasks 6
```

- It creates or reuses the worktree `../keepercent-overnight` on branch `overnight/<date>` (from `main`) and a dedicated simulator named "Keepercent Overnight". `caffeinate` keeps the Mac awake while it runs.
- A `done` task is fast-forwarded into `overnight/<date>` and pushed with the `tomioliveres` account, switching back to `atomdev1` afterwards. A `blocked` or `failed` task keeps its work on `auto/<task>` (unfinished changes are committed as `wip(...)`) and is skipped.
- It stops when the queue is empty, after `--max-tasks`, after two failures in a row (usually quota), or when the stop file exists: `touch "$(git rev-parse --git-common-dir)/overnight-STOP"` (remove it before the next run).

## In the morning

1. Read `../keepercent-overnight/build/overnight/<date>/summary.md`, then each task's `report.md` and screenshots in the same folder.
2. If the work is acceptable: `git merge --ff-only overnight/<date>` on `main`, then push `main`.
3. Blocked tasks list their open question in `report.md`; answer it in the queue entry and requeue the task.

## Safety

- The headless sessions run in `auto` permission mode with `Tools/Overnight/settings.json`, which denies `git push`, merges, resets, `gh`, `gentle-ai`, simulator erase/delete and `rm -rf`. Only the driver merges and pushes, and only the integration branch.
- Launches use in-memory `-KPData` fixtures; no personal store is opened.
- Screenshot verdicts are the model's (`self-verified`), not the author's.

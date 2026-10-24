---
name: verify-ui
description: "Trigger: /verify-ui, simulator verification. Claude Code adapter for the shared UI policy and Keepercent profile; records evidence without editing source."
license: Apache-2.0
metadata:
  author: tomasoliveres
  version: "1.1"
---

# Verify UI (simulator side, Claude Code)

Reply to the user in Spanish. This is the Claude Code adapter, not the global policy. First load `docs/ui-verification.md`, the installed `verify-interface` skill, its evidence reference, and the iOS adapter as resolved there. Keep this adapter's tool-specific workarounds local. If the Claude Simulator MCP is unavailable, use a permitted Computer Use route only if supported by this runtime and the profile; otherwise return `unverifiable` with missing capability.

**Read-only on code.** This skill never edits source, never commits, never merges. Defects go back to the implementing Claude Code session (`/auto-task` or an interactive one) through the handoff file (see `CLAUDE.md`, Workflow). This skill is now optional: an independent exact-SHA check the author asks for on top of `/auto-task`'s self-verification.

## 1. Pick the handoff

`H=$(git -C <repo> rev-parse --git-common-dir)/handoff`. Use the task given as argument, else the only file with `status: ready`. None ready → say so and stop. More than one → ask which.

## 2. Check out the exact commit, isolated

```bash
git -C <repo> worktree add --detach ../keepercent-verify <sha>   # first time
git -C ../keepercent-verify checkout --detach <sha>              # later runs
```

Before either command, check that the verification checkout is clean, belongs to this repository, and is not in use; never discard unrelated state. Never build from the main checkout: another session may be editing it. Confirm the launch route uses disposable data.

## 3. Launch ONE verifier

Use one foreground verifier with the shared policy, project profile, exact handoff screens/checks, and prior case ledger. Execute directly when capable unless the calling workflow requires an independent verifier; if delegation is required, use the runtime's configured verifier without forcing a model. Apply the shared incremental rules before this procedure; the full matrix below is for initial/full runs, not a demand to repeat unchanged evidenced cases:

1. Build: `xcodebuild -project Keepercent.xcodeproj -scheme Keepercent -destination 'platform=iOS Simulator,name=<device>' -derivedDataPath build/DerivedData build` inside `../keepercent-verify`.
2. Devices in sequence, **one booted at a time**: an iPhone first, then an iPad (`xcrun simctl list devices available` to pick names; shut the iPhone down before booting the iPad).
3. For each device: `simctl ui booted appearance light`, then `dark`.
4. Reach each screen:
   - if the commit supports launch arguments (T5.0 done): `xcrun simctl launch --terminate-running-process booted dev.tomioliveres.keepercent -KPScreen <screen> -KPData <demo|empty>`;
   - otherwise install and launch with the simulator MCP (`launch` with the built `.app`) and navigate with `inspect` + `tap`.
5. Prefer the MCP for structured evidence when available; use permitted Computer Use for visual surfaces it cannot expose. Confirm resulting state, not just tap success. Save screenshots to the profile's per-task/SHA/run evidence directory. The following workarounds apply to this MCP, not to Computer Use:
   - **Tap with `duration: 0.2`.** Plain short MCP taps are often not registered (toggles, pickers, buttons). A control that ignores a 0.2 s tap may be disabled by design; check its preconditions, e.g. Match Roster own-player toggles stay disabled until "Equipo propio" is chosen.
   - **The MCP screenshot right after a `tap` is stale** (captured before the animation), so it looks like the tap did nothing. After every tap, wait about 2 s (`sleep 2`), then judge from `xcrun simctl io booted screenshot <path>`. Never report taps as dead without that check.
   - After launch, wait until the app has rendered (it can take about 20 s) before the first screenshot; blank captures mean "not yet", not a defect.
   - **Text entry: tap the on-screen keyboard, never the MCP `text` action.** `text` pastes from the clipboard, and the text does not land in a SwiftUI `TextField`. Tap the field to bring up the software keyboard, screenshot it to locate the keys, then tap each key (`duration: 0.15`, about 1 s apart). Use backspace to clear existing characters. Confirm the field's value in a screenshot before saving. Mark text-entry checks `unverified` only if this also fails.
   - **Exporting a shared image:** the share sheet has no "Guardar imagen"; use "Guardar en Archivos", then copy the file from the simulator's File Provider Storage into the shots folder and read it at full size. A share-sheet thumbnail is not export proof.
6. Standard checks on top of the handoff's: empty data renders sensibly · every tappable zone is visibly tinted · sheets and alerts do not dismiss each other · text is readable in dark mode · nothing is clipped on iPhone.
7. Shut down the simulator. Return: `pass`, or numbered defects (what, where, device/appearance, screenshot path, the check it fails). A check that could not be exercised is `unverified`, never `pass`.

## 4. Write the verdict

Update only the handoff status, actual actor timestamp, and `## Verdict` with the shared case ledger, pending cases, and preserved history. Recheck the exact task/SHA before writing and read it back afterward. Mirror best effort to `keepercent/verify/<task-id>`; a failed file write/readback cannot produce a passing handoff. Do not change the handoff's target or checks.

Tell the user in two or three lines: the verdict, the worst defect if any, and the next step: *"Volvé a la sesión que implementó la tarea para corregir o cerrar"*. Leave the worktree in place for the next run.

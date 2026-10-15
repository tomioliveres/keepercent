# Reusable UI verification
Objective: shared evidence policy, capability-based execution, and a Keepercent profile. Branch: `codex/reusable-ui-verification`.
Delivery: ask-on-risk; forecast below 400 authored changed lines. Checks: skill validation, structural readback, independent dry-run scenarios; no app launch.

## Specs
- S1: "aplicá esas mejoras al flujo global" — install a reusable policy, retain the iOS adapter, remove fixed model routing, combine structured tools with Computer Use, and bound infrastructure recovery.
- S2: "ajustá Keepercent para usarlo" — link the shared policy through a project profile and existing runtime adapters; preserve exact-SHA isolation, authoritative handoffs, and legacy fields.
- S3: "una base reutilizable para los próximos proyectos" — keep platform/project details out of the common policy; record per-case evidence and explicit incremental provenance.

## Tasks
- T1 [S1,S3] inline, implemented; structural checks passed — global policy and iOS adapter; no writer trigger. Installed user skills are outside the project Git repository; record hashes rather than commit the home repository.
- T2 [S2] inline, implemented; structural checks passed — project profile and routing, same understood workflow. Commit tracked project deliverables on the feature branch; preserve pre-existing untracked adapters as local configuration.
- T3 [S1-S3] delegated verification, passed; native assessment pending — independent read-only scenario evaluation (risk item 3: consumed workflow contracts), then parent spot check and native assessment if applicable.

## Log
- L1 (2026-10-15): "Dale, aplicá esas mejoras al flujo global y ajustá Keepercent para usarlo, así nos queda una base reutilizable para los próximos proyectos."
- L2: Authorized implementation follows the preceding audit. Existing untracked `.claude/`, app-icon, design, task and tmp files are unrelated except the two explicitly targeted local skill adapters. Preserve all other content. Start from `df9b87661be99b2d0a8861b72c26308298e8d327`; do not resume icon work.
- L3: Use direct execution when capabilities suffice, subject to the calling workflow's independent-verifier requirement; model upgrades are not automatic. This implements the accepted review of fixed delegation, not a change to permissions.
- L4: Behavioral RED is not meaningful for instruction-only changes. Validate syntax/references plus fresh-context scenarios; do not claim UI, runtime, performance or accessibility proof. Global files require a sandbox-approved write. No push, PR or merge.

- L5: Installed/read back common policy and iOS adapter with approved global write. Added project profile and updated both local adapters. Ruby/Psych parsed all four skill frontmatters; relative links, fences, placeholders and `git diff --check` passed. Fixed pre-existing unquoted adapter descriptions while updating stale Sonnet metadata.
- L6: Bundled `quick_validate.py` unavailable: both system and bundled Python lack PyYAML. Used real Ruby YAML parsing plus structural checks instead; no dependency installation or claimed validator success. Refreshed registry: 19 skills. Independent scenarios and native assessment pending.
- L7: Independent scratch-copy evaluation: S1/S2 pass; S3 blocked by the old iOS hard rule requiring current-SHA evidence for every case despite shared cross-SHA reuse. One scoped correction now distinguishes executed from carried-forward cases; blocker-only recheck pending. Four realistic desktop/iOS/incremental/Claude scenarios otherwise produced scoped evidence and no false pass.
- L8: Blocker-only recheck passed: S1/S2/S3 all pass in independent instruction dry runs. Parent repeated real Ruby/Psych YAML parsing successfully on all four skills. No UI/build/accessibility test or speed improvement claimed. Installed skills and local adapters are intentionally not added to the project Git candidate.
- Installed SHA-256 `verify-interface/SKILL.md`: `bc5adfceaad39fdbd0958085f7729a1ec321ed7d126018a5cf16f77b2ff1794c`.
- Installed SHA-256 `verify-interface/references/evidence.md`: `099a21eecee07368ccdddb7e0bf06e1debbf50c11f566cb9588b26915acf2b59`.
- Installed SHA-256 `verify-ios-simulator/SKILL.md`: `ffe22a10880942bef65d838d9c900a8fdb51c2d04879998969a3810fd851863f`.
- Installed SHA-256 `verify-ios-simulator/references/execution-evidence.md`: `03991ec11cbc774843987a618709ba5cba9d166ac7550cc04985cfeb356bd30d`.

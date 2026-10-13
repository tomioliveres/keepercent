# T6.2 — README foundations and visual assets

## Current objective

Explain the integrated app, its native offline architecture and actual AI usage, then add source-bound screenshots and a short interaction GIF. T6.2 remains open until its visual assets and rendered README are checked.

## Resumption and preserved history

- RF-1 was completed on the independent `docs/T6.2-readme` branch: `b58c4fe5712d44bdacf3c6e70f2e8d64e86c56eb` (README foundations) and `29f9135d43dec89659e0db67662b4ae1029a1b5b` (verification bookkeeping), based on `8f2c1b44b21a1cf3f1876ed656d4bbe971d592b3`.
- That branch, its full task document and Engram observation #4887 preserve the original scope, claim evidence and checks. RF-1 is not reimplemented or claimed integrated by this resumption.
- Current user authorization resumes T6.2 after T6.11 integration/publication and T6.1's documentary closure. The old parallel-task exception, exclusion of match/club functionality and ready T6.11 instructions are historical, not current instructions.
- Resume branch: `task/T6.2`, based on integrated `main` at `34a2bd4af279dc1a1ce69a01322d0b1f2f69b193`. Reuse prior README content selectively; never restore the old master ledger or merge the old branch wholesale.

## Authorized scope and constraints

- This slice may edit `README.md`, this feature document and only the T6.2 entry in `odd/tasks/keepercent.md`.
- English artifacts; no app/Domain/project changes, new fixtures, dependency changes or source implementation.
- Preserve T6.1/T6.11 closure, accepted debt, manual VoiceOver pending, every historical handoff, `docs/T6.2-readme`, and preexisting untracked `.claude/` and `tmp/`.
- OpenCode does not boot a simulator. Claude Code or Codex desktop captures visual assets from the exact handed-off SHA; no third-party/reference material is used.
- No merge, push, pull request or next task is authorized by this task start.

## Work units and acceptance

- [x] RF-1 Historical README foundations: purpose, architecture, offline/export boundaries and development-AI versus deterministic runtime insights. Prior branch only; source claims were scoped to its old base. Historical checks passed (relative links/fences and whitespace); native assessment passive. No rendered README or visual-assets pass was claimed.
- [x] RF-2 Reuse and refresh README foundations for the integrated match/club app.
  - Route: delegated direct; current-source preparation and multiple nontrivial documentation files require one bounded writer.
  - Acceptance: explain optional own club, match-scoped history, stable identity/snapshots and scoped reports without claiming broader runtime verification. Correct obsolete generative runtime/video-player promises and stale MVP status. Preserve native/offline boundaries and explicit sharing exception. Keep README scannable and links valid.
  - Checks: `git diff --check`; balanced Markdown fences; relative file/fragment links inspected; all material claims backed by current source paths; only authorized documentation paths changed; parent structural readback.
  - TDD exception: passive documentation has no meaningful behavioral RED. Domain tests, app build and simulator are N/A for this work unit; no new functional proof is claimed.
  - Progress: README refresh implemented, selectively reusing RF-1 prose with current match/club claims. Writer verification and parent structural readback passed; parent repeated `git diff --check` and confirmed the source/project/context comparison is empty. Commit and native assessment evidence will be recorded after the documentation work unit is committed; RF-3 remains open.
- [ ] RF-3 Capture and integrate public README screenshots and a short GIF.
  - Route: external visual capture first, then a bounded asset/documentation writer. No OpenCode simulator launch.
  - Acceptance: use synthetic demo data and Keepercent-only images; record exact SHA, device/OS, appearance, locale, launch arguments and any data preparation. Show a small representative set of current screens and a short linked-card interaction, not a full UI acceptance matrix. Do not invent a populated own-history demo: `demoOwnRoster` creates a roster without attributing prior matches.
  - Intended later asset directory: `docs/assets/readme/`; not part of RF-2's allowed edit surface. Do not add broken image links or placeholder assets before real captures exist.
  - Checks: inspect actual images/GIF for legibility and content, relative asset links and rendered Markdown; document missing visual capability as unavailable rather than pass.
  - Progress: pending external handoff; T6.2 remains unchecked.

## Delivery and recovery

- Strategy: `single-pr`, carried forward from RF-1; no PR/publishing authorized. Forecast for this resumption: about 200–300 authored documentation lines before assets. Reassess actual growth before the next commit if the accumulated range exceeds the advisory delivery budget.
- Historical authored count: 164 across the prior branch's two work-unit/bookkeeping commits; those commits are not in this branch. Current resumption is uncommitted; record new commit evidence separately, not as integration of the historical branch.
- Rollback: RF-2's README and T6.2 documentation only; no app behavior or data changes.
- Mirror: `odd/readme-foundations/tasks/resume-34a2bd4`, with the complete current document and locator; historical observation #4887 at the original topic and the original branch remain recovery evidence.
- Next: complete RF-2, then hand RF-3 to the external capture runtime. No full task closure until visual assets are addressed.

## RF-2 current-claim evidence

Current source inspection at the resumption base supports these claims; it is not a new runtime or binary audit:

| README claim | Current evidence |
| --- | --- |
| Optional own club alongside rival-only scouting | `Keepercent/Features/Sessions/NewSessionSheet.swift:30–42` accepts an optional own team and separate inclusion/participants; `Keepercent/Features/Teams/TeamsView.swift:87–92,117–126` separates Own Team Roster configuration from My club history. `Keepercent/Features/MyClub/MyClubView.swift:14–63` shows attributed historical people. |
| One match or All matches; stable identities and historical roster facts | `Keepercent/Persistence/ScopedMatchData.swift:6–55,76–96` filters match shots, selects per-match snapshots and prefers current roster headers for All with historical fallback. `StoredMatchParticipant.swift:5–24` copies UUID, number, name, role and handedness. |
| Own-goalkeeper history uses attribution, not today's roster membership | `Keepercent/Features/MyClub/OwnGoalkeeperCardView.swift:7–34` filters by `playerID` and selected scope, reuses shared goalkeeper content and forwards scope to reports. |
| Scoped rival/own reports with deliberate export | `Keepercent/Features/Report/TeamReportView.swift:14–66,96–106` projects the selected scope and UUID into report values, renders with `ImageRenderer` and exports via `ShareLink`. |
| Deterministic runtime text, distinct from development AI | `Keepercent/Insights/InsightTextView.swift:7–17` directly calls `TemplateInsightWriter`; the preserved RF-1 architecture describes pure-value `StatsEngine` and template/pattern phrasing. No runtime model availability promise is retained. |
| Native drawing/bars, manual video metadata, no fabricated own demo history | `Keepercent/DesignSystem/LinkedZonesView.swift:35–103,318–345` shares native goal/court and outcome views; `Keepercent/Features/Sessions/NewSessionSheet.swift:44–60` collects session kind/date. Parent scoped source inspection found no in-app player; `Keepercent/Persistence/DemoDataSeeder.swift:15–28` seeds an own roster without historical attribution. |
| Current platform and limited status | `CLAUDE.md:3,8–16,35–44` defines personal-project/native/platform conventions. The master ledger's T6.1 closure records incomplete task-wide proof and pending manual VoiceOver; T6.11 is integrated, not reopened. |

## RF-2 writer verification

- Passive documentation: no meaningful RED/GREEN; Domain tests, builds and runtime checks are N/A and were not run.
- `git diff --check`: passed with no output. `git diff --name-only`: only `README.md` and `odd/tasks/keepercent.md` (this untracked document is absent from Git diff until staged by the parent).
- `git diff --numstat`: README 61 additions / 18 deletions; master ledger 1 addition / 1 deletion, only the T6.2 line. This document is 69 lines, including preserved parent content, and remains untracked.
- `git diff 34a2bd4af279dc1a1ce69a01322d0b1f2f69b193 -- Domain Keepercent Keepercent.xcodeproj CLAUDE.md`: empty; no source/project/context changes.
- Manual structural inspection: all 9 README relative links resolve to observed files/directories; this document has no Markdown links or fences, and the changed T6.2 ledger link resolves to this document. README has two balanced fenced blocks (four delimiters), valid heading/table structure and no image links or fragment targets. No external URL, rendered Markdown, simulator, image or GIF check is implied.
- Parent must recheck the final working tree and this untracked document before staging; writer checks do not substitute for parent readback.
- Inventory includes this preexisting untracked task document as well as tracked README/master-ledger changes; `.claude/` and `tmp/` remain untouched.
- Parent structural readback and repeated whitespace/source-boundary checks passed. RF-2's documentation outcome is complete; commit/evaluation bookkeeping follows. RF-3 remains unchecked for external capture; no assets or handoffs were prepared by the writer.

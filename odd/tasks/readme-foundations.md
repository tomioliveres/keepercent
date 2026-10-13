# T6.2 — README foundations and visual assets

## Current objective

Explain the integrated app, its native offline architecture and actual AI usage, then add source-bound screenshots and a short interaction GIF. T6.2 remains open until its visual assets and rendered README are checked.

## Resumption and preserved history

- RF-1 was completed on the independent `docs/T6.2-readme` branch: `b58c4fe5712d44bdacf3c6e70f2e8d64e86c56eb` (README foundations) and `29f9135d43dec89659e0db67662b4ae1029a1b5b` (verification bookkeeping), based on `8f2c1b44b21a1cf3f1876ed656d4bbe971d592b3`.
- That branch, its full task document and Engram observation #4887 preserve the original scope, claim evidence and checks. RF-1 is not reimplemented or claimed integrated by this resumption.
- Current user authorization resumes T6.2 after T6.11 integration/publication and T6.1's documentary closure. The old parallel-task exception, exclusion of match/club functionality and ready T6.11 instructions are historical, not current instructions.
- Resume branch: `task/T6.2`, based on integrated `main` at `34a2bd4af279dc1a1ce69a01322d0b1f2f69b193`. Reuse prior README content selectively; never restore the old master ledger or merge the old branch wholesale.

## Authorized scope and constraints

- RF-2 edits are confined to `README.md`, this feature document and the T6.2 entry in `odd/tasks/keepercent.md`. RF-3 additionally authorizes the four captured assets `docs/assets/readme/scouting.png`, `shooter-card.png`, `goalkeeper-card.png` and `shooter-interaction.gif`; no other media or source files.
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
  - Progress: README refresh implemented, selectively reusing RF-1 prose with current match/club claims. Writer verification and parent structural readback passed; parent repeated `git diff --check` and confirmed the source/project/context comparison is empty. Work unit `ea5ec6fc6dbf85704f1f65bd550c4224a36d021e` (`docs(readme): document integrated match and club scouting`), 131 additions / 19 deletions across three Markdown files. Native committed assessment from explicit base `34a2bd4af279dc1a1ce69a01322d0b1f2f69b193`: passive / `non_executable_only`, `review_due: false` / `passive`; unrelated untracked inventory explicitly excluded. No START, consent, reviewer, acknowledgement or review receipt. RF-3 remains open.
- [ ] RF-3 Capture and integrate public README screenshots and a short GIF.
  - Route: external visual capture first, then a bounded asset/documentation writer. No OpenCode simulator launch.
  - Acceptance: use synthetic demo data and Keepercent-only images; record exact SHA, device/OS, appearance, locale, launch arguments and any data preparation. Show a small representative set of current screens and a short linked-card interaction, not a full UI acceptance matrix. Do not invent a populated own-history demo: `demoOwnRoster` creates a roster without attributing prior matches.
  - Asset directory: `docs/assets/readme/`, RF-3 only. Integrate unchanged captured `scouting-2.png` as `scouting.png`, the top shooter/goalkeeper card PNGs and `shooter-interaction.gif`. Short captions describe visible summaries and filter selection/clearing, not complete cards or visible Directions arrows. No fake assets or broader verification claims.
  - Checks: inspect actual images/GIF for legibility and content, relative asset links and rendered Markdown; document missing visual capability as unavailable rather than pass.
  - Progress: capture-only handoff passed at exact `e377111e6b533f89812abb84faac346c84037ba3`, iPhone 17 / iOS 26.1, portrait/light/default Dynamic Type, English/en_US. External Claude inspection covered the PNGs and GIF's motion (84 frames, about 8.5 seconds); OpenCode exploration inspected PNGs and one static GIF frame, with parent spot readback of the scouting capture. The user copied the four assets; the writer preserved their bytes and integrated README links and captions. Rendered Markdown inspection is unavailable in the exposed tools and remains explicitly pending, not passed. RF-3 and T6.2 remain unchecked until that requirement is resolved.

## Delivery and recovery

- Strategy: `single-pr`, carried forward from RF-1; no PR/publishing authorized. Forecast for this resumption: about 200–300 authored documentation lines before assets. Reassess actual growth before the next commit if the accumulated range exceeds the advisory delivery budget.
- Historical authored count: 164 across the prior branch's two work-unit/bookkeeping commits; those commits are not in this branch. Current resumption: 150 authored changed lines in `ea5ec6f`; final bookkeeping count is recorded in the session recovery summary. This is selective reuse, not integration of the historical branch.
- Rollback: RF-2's README and T6.2 documentation only; no app behavior or data changes.
- Mirror: `odd/readme-foundations/tasks/resume-34a2bd4`, with the complete current document and locator; historical observation #4887 at the original topic and the original branch remain recovery evidence.
- Next: inspect the rendered README before parent-owned review and closure. Capture and asset integration are complete; no rendered pass or full task closure is claimed.

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
- Parent structural readback and repeated whitespace/source-boundary checks passed. RF-2's documentation outcome and passive committed assessment are complete. RF-3 remains unchecked for external capture; no assets or handoffs were prepared by the writer.

## RF-3 asset provenance and verification

- Capture source: `e377111e6b533f89812abb84faac346c84037ba3`, authoritative capture-only pass in shared `.git/handoff/T6.2.md`; that handoff remains unchanged. Device: iPhone 17, iOS 26.1 (23B86), portrait, light, default Dynamic Type, English/en_US; status bar set to 9:41 during capture and cleared afterwards.
- Independent launches: `-KPScreen scouting -KPData demo`, `-KPScreen shooterCard -KPData demo`, `-KPScreen goalkeeperCard -KPData demo`, each with `-AppleLanguages (en) -AppleLocale en_US`. Data is synthetic and in-memory; no own-club history, persistent data preparation or third-party material is represented.
- Exact source directory: `../keepercent-verify/build/readme/T6.2/`. The user copied the assets into `docs/assets/readme/`; this writer did not copy, modify or re-encode binary inputs. All four source/destination SHA-256 pairs match:

| Source filename | Public filename | SHA-256 |
| --- | --- | --- |
| `scouting-2.png` | `scouting.png` | `56549157d78adc70cc25acfaa5618052c6d93f2eefe81934a2c86766990077fa` |
| `shooter-card.png` | `shooter-card.png` | `67b5e745db3924b4026e8f18f65fa8055b909ecfcc0bfe937f0eb1c63f77778d` |
| `goalkeeper-card.png` | `goalkeeper-card.png` | `f34bbe8aaae64b055a935e1df1285677f4a2e4d11ed6bc463a5257e1a6bc7b89` |
| `shooter-interaction.gif` | `shooter-interaction.gif` | `70a70a18fdf543c003e855e9ca46bf33a32dcbffae9e5be1c1ba980ac0a11495` |

- Native `sips` readback: each PNG is 1206 × 2622; GIF is 450 × 978. Writer Read inspection covered all three public PNGs and one static GIF frame, not GIF playback. External Claude capture proof records actual motion: 84 frames, 8.49 seconds, native AVFoundation/ImageIO encoding without installations or external services.
- Visible content: scouting shows both maps and 18 field shots, with the All matches selector offscreen. Top cards show All matches and rival demo identities: Jordi Ferrer (#3), 2 shots / 0 goals / 0%; Marc Puig (#1), 12 shots on target / 4 saves / 33%. Their origin courts are partly offscreen. README captions describe selected visible portions, not whole cards or reports.
- GIF caption is limited to court-origin filter selection and repeated-tap clearing. Capture evidence also records a Directions mode change; no visible-arrow claim or diagnosis is made.
- Passive documentation and existing images have no meaningful behavioral RED/GREEN. No Domain test, app build or simulator run is required or performed by this writer. Capture-only proof does not establish task-wide functional or accessibility acceptance.
- Writer checks: `git diff --check` passed; `git diff --name-only` lists only the three authorized Markdown files; `git diff e377111e6b533f89812abb84faac346c84037ba3 -- Domain Keepercent Keepercent.xcodeproj CLAUDE.md` is empty. Manual structure checks resolve all 14 README relative links (including four full-size media links and the provenance fragment), four matching image sources with descriptive alt text and width 260 only, and two balanced fenced blocks. Rendered layout and GIF playback were not checked here.
- Parent structural readback and repeated `git diff --check` passed. Native assessment of the staged seven-path media/documentation unit returned passive / `non_executable_only`, 47 authored text lines, `review_due: false` / `passive`, with unrelated untracked inventory explicitly excluded. No review transaction or receipt is required for these passive documents/images; the local integration commit is recorded in the full recovery mirror.
- Pending acceptance: rendered Markdown inspection is unavailable in the exposed tools. Structural checks do not substitute for a rendered pass; RF-3 and T6.2 remain unchecked. No merge, push or task closure is authorized by the capture result.

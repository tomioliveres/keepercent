# Keepercent — UI/UX and accessibility audit

- **Date:** 2026-10-19 · **Commit audited:** `9abd1a4` (branch `codex/layered-app-icon`) · **Scope:** read-only, no source changes.
- **Method:** SwiftUI source review of `Keepercent/Features`, `DesignSystem`, `Insights`, plus simulator captures through the `-KPScreen` / `-KPData` launch router.
- **Devices:** iPhone 17 (iOS 26.1) and iPad Air 11" M3, portrait. Light and dark. Languages en, es, es-419. One pass at Dynamic Type `accessibility-extra-extra-large` (AX3).
- **Evidence:** `design/ux-audit/screenshots/` (file names follow `<device>-<lang>-<appearance>-<screen>-<data>.png`).

## Tooling recommendation

| Tool | Use it for | Verdict |
|------|-----------|---------|
| iOS Simulator (`simctl` + Claude Simulator MCP) | Screenshots per screen, appearance, language and text size; light interaction | **Primary.** The launch router makes every main screen one command away, so the whole matrix can be repeated cheaply. |
| `XCUIApplication.performAccessibilityAudit()` | Automated contrast, hit-region, Dynamic Type clipping and missing-label checks | **Add next, as a task.** It needs a UI test target change, so it was out of scope for a read-only pass. It catches the class of issue in F-02, F-05 and F-09 automatically and keeps catching it. |
| Xcode Accessibility Inspector | Manual VoiceOver order and labels on one screen | Spot checks only; slow for a full matrix. |
| Design skills in this environment | — | None targets SwiftUI/HIG; not useful here. |

## Overall state

The foundation is better than most first design passes: system typography everywhere (no fixed font sizes), semantic colours with a named `Palette`, `ContentUnavailableView` for most empty states, careful VoiceOver work on the drawn goal and court (T6.1-A), plural-aware string catalog, full es / es-419 coverage. Goalkeepers are marked with two channels, not colour alone.

The weak spots cluster in four areas:

1. **The shot-entry screen on iPhone** — the most-used screen is a long scroll with the deciding controls below the fold.
2. **Colour meaning** — the dark-mode heatmap scale is practically flat, and white text sits on green/orange buttons.
3. **Dynamic Type at accessibility sizes** — fixed-width layouts and an overlay badge break.
4. **Development leftovers and iOS idiom drift** — a debug scaffold in the menu, a share icon that navigates, a visible accessibility-only button.

## Severity scale

- **High** — blocks or seriously degrades a core task, or fails a WCAG/HIG requirement for a common setting.
- **Medium** — noticeable friction, inconsistency, or failure at a less common setting.
- **Low** — polish.

## Findings

| ID | Sev. | Screen | Issue |
|----|------|--------|-------|
| F-01 | High | Session entry (iPhone) | Core controls and outcome feedback are below the fold |
| F-02 | High | Cards, Scouting, 7 m (dark) | Heatmap scale is nearly flat in dark mode |
| F-03 | High | Session entry | White text on green/orange outcome buttons (2.2:1) |
| F-04 | High | Teams (empty) | No empty state on iPhone; wrong one on iPad |
| F-05 | High | Roster, shooter grid (AX sizes) | Goalkeeper badge covers the shirt number; names cut to 3 letters |
| F-06 | Medium | Session entry | "Left post, top" accessibility button is visible to everyone |
| F-07 | Medium | Teams menu | Developer scaffold shipped in the ⋯ menu |
| F-08 | Medium | Goalkeeper card | Share icon navigates instead of sharing |
| F-09 | Medium | Cards (all sizes, worst at AX) | Scope selector clips/truncates |
| F-10 | Medium | Session entry (es) | Chip row overflows and wraps in Spanish |
| F-11 | Medium | Session entry | Chips are ~32 pt tall and expose no selected state |
| F-12 | Medium | Session entry | No VoiceOver announcement when a shot is saved or removed |
| F-13 | Medium | Session entry | Pinned header duplicates the title and eats space |
| F-14 | Medium | Roster | Editing a player is only reachable by long-press |
| F-15 | Medium | Match roster sheet | Locked rows are unexplained and doubly dimmed |
| F-16 | Medium | Edit player | Archive confirmation has no visible Cancel on iPhone |
| F-17 | Medium | iPad cards, Scouting, Session portrait | Content stretches to full width; no readable width |
| F-18 | Medium | Team report | Card fixed at 320 pt; does not adapt to iPad or text size |
| F-19 | Medium | All custom screens | Section titles are not VoiceOver headings |
| F-20 | Low | New session sheet | Kind and date sit below the roster list |
| F-21 | Low | Scouting | "Effectiveness / Save rate" does not say whose |
| F-22 | Low | Cards | Generic nav titles; insight and "Shot shape" fully secondary |
| F-23 | Low | Shot log | "Done" on the leading side; delete only by swipe |
| F-24 | Low | Own team roster | Hand-built form; error appears far from the field |
| F-25 | Low | Breakdown chart | Fixed 52 pt name column and black-on-colour labels |
| F-26 | Low | Menus and titles | Mixed title/sentence case; "Scouting" left in English |
| F-27 | Low | 7 m section | Five-figure stat line is hard to scan |

### F-01 · High · Session entry is a long scroll on iPhone

- **Evidence:** `iphone-en-light-sessions-demo.png`, `iphone-es-light-sessions-scrolled.png`; `Features/Sessions/SessionView.swift:256` (`verticalLayout`).
- **HIG:** Layout — put the primary task within reach; minimize scrolling on frequently used screens. iOS 26 "Designing for iPhone": important content and controls should stay in view.
- **What happens:** The order is shooter grid → goal → court → attacking side → goalkeeper → chips → *Goal or saved?* → last-shot card / Undo. Choosing a shooter, a target and an origin needs about two screens of scrolling. The outcome question and the Undo confirmation appear below the court, out of sight, at the moment the scout needs them. The Rival/Own switch, which changes what the shooter section means, comes after the goal and court.
- **Suggested fix:**
  - Move Rival/Own and the active goalkeeper into a compact bar above the shooter grid.
  - Show the outcome question and the last-shot card as a bottom overlay (`.safeAreaInset(edge: .bottom)` with a glass background) so they are always visible.
  - Consider a horizontally scrolling shooter strip on compact width instead of a multi-row grid.

### F-02 · High · Heatmap scale is nearly flat in dark mode

- **Evidence:** `iphone-en-dark-scouting-demo.png`, `ipad-en-dark-goalkeeperCard-demo.png`; `DesignSystem/HeatmapColor.swift:22-23`.
- **HIG / WCAG:** Color — don't rely on colour alone; make sure colours work in both appearances. WCAG 1.4.11 asks for 3:1 between meaningful graphic states.
- **What happens:** In dark mode the low and high ends of the scale are `(0.20, 0.39, 0.59)` and `(0.14, 0.35, 0.63)`, a **1.12:1** contrast. A 0/1 cell and a 1/1 cell look the same; even "no data" vs. high is only 1.39:1. Light mode works but is modest (2.06:1). The numbers in the cells save the meaning, so this is a readability failure, not a data-loss failure.
- **Suggested fix:** Redefine the dark ramp so lightness rises with the rate (for example dark navy → bright cyan), aim for at least 3:1 end to end, and add a small legend under each heatmap. Check it with `performAccessibilityAudit(for: .contrast)`.

### F-03 · High · White text on green/orange outcome buttons

- **Evidence:** `Features/Sessions/ShotEntryContextPanel.swift:178` (`.borderedProminent` + `.tint(Palette.goal)` / `.tint(Palette.saved)`); `DesignSystem/Palette.swift:32`.
- **HIG / WCAG:** Color and Accessibility — text needs 4.5:1 (3:1 for large bold text).
- **What happens:** `.borderedProminent` draws white labels. White on systemGreen is **2.22:1** and on systemOrange **2.2:1**. Both fail even the large-text threshold. These are the two buttons a scout hits under time pressure in a bright gym.
- **Suggested fix:** Use dark labels on these fills (the way `onBrandAmber` already handles amber) or use darker shades. Keep a second channel (an SF Symbol such as `soccerball` / `hand.raised`) so the choice survives without colour.

### F-04 · High · Missing empty state for "no teams"

- **Evidence:** `iphone-en-dark-teams-empty.png` (blank list), `ipad-en-light-teams-empty.png` ("Select a Team"); `Features/Teams/TeamsView.swift:73`, `:108`.
- **HIG:** Empty states (iOS 26 "Loading and empty states") — explain why the screen is empty and offer the next action.
- **What happens:** With no teams, iPhone shows "Rival Teams" over a blank list. iPad says "Choose a rival team from the list", but the list is empty and the sidebar is collapsed. A first-time user has no explanation and must find the small `+`.
- **Suggested fix:** When `teams.isEmpty`, show `ContentUnavailableView` in the sidebar with "No rival teams yet" and a "New Team" button in its `actions:`. Make the detail placeholder conditional on whether any team exists.

### F-05 · High · Roster tiles break at accessibility text sizes

- **Evidence:** `iphone-es419-AX3-teams.png`, `iphone-es419-AX3-sessions.png`; `Features/Teams/PlayerTileView.swift:74` (badge), `:87` (`lineLimit(1)`).
- **HIG:** Typography — support Dynamic Type, including accessibility sizes; layouts should adapt rather than overlap or truncate.
- **What happens:** At AX3 the glove badge (`.caption2`) grows with text while the tile does not, so it covers the goalkeeper's shirt number, the one thing the tile must show. Names truncate to "Mar…", "Jor…". The add tile's label wraps letter by letter ("Nue-vo nú-mero").
- **Suggested fix:**
  - Cap the badge with `.dynamicTypeSize(...DynamicTypeSize.xxxLarge)` or size it from `@ScaledMetric` with a ceiling.
  - Let the name use two lines at accessibility sizes.
  - Increase the grid's adaptive minimum when `dynamicTypeSize.isAccessibilitySize`.

### F-06 · Medium · An accessibility-only control is visible to everyone

- **Evidence:** every `*-sessions-demo.png` shows a full-width "Left post, top" button under the goal; `DesignSystem/GoalView.swift:124`.
- **HIG:** Accessibility — accommodations should not add unexplained UI for everyone. Buttons should describe an action.
- **What happens:** The button exists so VoiceOver can reach the narrow top-left post (T6.1-A). Visually it reads as a random setting, it is the only post with its own button, and in Spanish it reads "Poste izquierdo, arriba".
- **Suggested fix:** Expose it only to assistive technologies: `.accessibilityRepresentation` on the goal, or an `.accessibilityAction(named:)`. Alternatively, widen the post hit band so no separate control is needed. Keep the XCTest from T6.1-A green.

### F-07 · Medium · Developer scaffold shipped in the menu

- **Evidence:** `Features/Teams/TeamsView.swift:94` — `Button("Drawing Scaffold (T2.x)")`, translated as "Prueba de dibujo (T2.x)".
- **HIG:** Menus — only include commands that make sense to people.
- **Suggested fix:** Wrap it in `#if DEBUG`, as the launch router already is.

### F-08 · Medium · Share icon that navigates

- **Evidence:** `Features/GoalkeeperCard/GoalkeeperCardView.swift:50` — `Label("Team Report", systemImage: "square.and.arrow.up")` pushes a screen.
- **HIG:** SF Symbols / Icons — `square.and.arrow.up` means "open the share sheet". Reusing it for navigation breaks the expectation.
- **Suggested fix:** Use `doc.text.magnifyingglass` or `list.clipboard` with a "Team Report" label, or have the button open the share sheet directly with the rendered image.

### F-09 · Medium · Scope selector clips

- **Evidence:** `iphone-es419-AX3-goalkeeperCard.png` ("Todos los partidos" clipped vertically); `Features/Scouting/MatchScopePicker.swift:10`. This is the known "truncated selector" observation.
- **HIG:** Pickers / Menus; Typography.
- **What happens:** A bare `Picker` outside a `Form` renders as a menu button. Long match labels ("BM Serra · 20 sept 2026 · Match 2") and accessibility sizes overflow it.
- **Suggested fix:** Use `Menu` with a `Label` that can wrap, or move the scope into the toolbar (`ToolbarItem(placement: .principal)` or a filter button). Format match options shorter (date + kind).

### F-10 · Medium · Chip row overflows in Spanish

- **Evidence:** `iphone-es-light-sessions-scrolled.png` ("Desde la derecha" wraps to two lines); `Features/Sessions/ShotEntryContextPanel.swift:146`.
- **HIG:** Localization — leave room for text expansion (Spanish runs about 30–60 % longer here: "From Left" → "Desde la izquierda", "Jump" → "En suspensión").
- **Suggested fix:** Lay the chips out with `ViewThatFits` (HStack → VStack), or a flow layout, or use a segmented `Picker` with short labels ("Izq. / Centro / Der.") plus full accessibility labels.

### F-11 · Medium · Chips are small and do not expose their state

- **Evidence:** `Features/Sessions/ShotEntryContextPanel.swift:192` — subheadline text + 6 pt vertical padding ≈ 32 pt tall, `.buttonStyle(.plain)`, no `.isSelected` trait.
- **HIG:** Buttons — 44×44 pt minimum hit target. Accessibility — convey state to VoiceOver.
- **Suggested fix:** Add `.frame(minHeight: 44)` or `.contentShape` with padding, and `.accessibilityAddTraits(isSelected ? .isSelected : [])`. iOS 26 alternative: `.buttonStyle(.glass)` / `.glassProminent` for the selected chip.

### F-12 · Medium · Saving a shot is silent for VoiceOver

- **Evidence:** `Features/Sessions/SessionView.swift:451` sets `lastShotCard`; `:183` plays a haptic. There is no announcement.
- **HIG:** Accessibility — announce important changes that happen outside the focused element.
- **Suggested fix:** After a save or undo, post `AccessibilityNotification.Announcement(summary).post()`, or give the card `.accessibilityAddTraits(.updatesFrequently)` and move focus with `@AccessibilityFocusState`.

### F-13 · Medium · Pinned header duplicates the title

- **Evidence:** `iphone-es419-AX3-sessions.png` (the header fills a third of the screen); `Features/Sessions/SessionView.swift:135`, `:202`.
- **HIG:** Navigation bars — the title already identifies the screen. Don't pin non-essential content above scrolling content.
- **What happens:** The team name appears in the inline nav title and again as a `title3` header. The header sits outside the `ScrollView`, so on iPhone, and especially at large text sizes, it permanently reduces the space for entry.
- **Suggested fix:** Drop the duplicate name. Put "Live · 20 Sep · 20 shots" in the nav subtitle (iOS 26 `.navigationSubtitle`), or move it inside the scroll content.

### F-14 · Medium · Editing a player needs a hidden gesture

- **Evidence:** `Features/Teams/RosterGridView.swift:54` — edit lives only in `.contextMenu`. A tap opens the card.
- **HIG:** Context menus — never make a context menu the only way to reach a command.
- **Suggested fix:** Add an "Edit" button to the shooter/goalkeeper card toolbar, or an Edit mode on the roster. Add `.accessibilityAction(named: "Edit")` on tiles.

### F-15 · Medium · Locked roster rows are unexplained

- **Evidence:** `Features/Sessions/MatchRosterSheet.swift:42` (lock icon `accessibilityHidden`), `:61` (`.opacity(0.5)` on top of `.secondary`), `:123` (`.red` instead of `Palette.error`). This is the known "locked toggle clarity" observation.
- **HIG:** Toggles; Accessibility — disabled controls should say why.
- **What happens:** Players who already have shots can't be removed. The only cue is a small lock, hidden from VoiceOver. Unselected rows get secondary colour *and* 50 % opacity, which drops them well below readable contrast.
- **Suggested fix:**
  - Add a footer line or `.accessibilityHint("Has recorded shots in this match")` on locked rows.
  - Use either the secondary colour or `.disabled` dimming, not both.
  - Use `Palette.error`.

### F-16 · Medium · Archive confirmation without a visible Cancel on iPhone

- **Evidence:** `Features/Teams/PlayerEditorView.swift:101`. The `.cancel` button exists in code, but on iOS 26 `confirmationDialog` renders as a popover-style action sheet that hides the cancel button and relies on tapping outside. This is the known "Remove Player" observation.
- **HIG:** Action sheets / Alerts — destructive confirmations should offer an obvious way out.
- **Suggested fix:** For a consequential, single-choice confirmation use `.alert` with explicit "Archive" (destructive) and "Cancel" buttons. Keep `confirmationDialog` for multi-option menus.

### F-17 · Medium · iPad layouts stretch to full width

- **Evidence:** `ipad-en-light-sessions-demo.png` (giant goal, still scrolls), `ipad-en-dark-goalkeeperCard-demo.png` (full-width text lines and heatmap); `Features/Sessions/SessionView.swift:228` (three columns only when width > height).
- **HIG:** Designing for iPadOS / Layout — use readable content widths and take advantage of the larger canvas.
- **Suggested fix:**
  - Cap the card and scouting content at a readable width (`.frame(maxWidth: 700)`) or arrange heatmaps side by side.
  - For session entry in iPad portrait, use two columns (shooter + context | goal + court) instead of one.
  - Landscape three-column was **not verified** in this pass (simulator rotation was not driven).

### F-18 · Medium · Team report fixed at 320 pt

- **Evidence:** `Features/Report/TeamReportView.swift:60`, `Features/Report/TeamReportCardView.swift:103`.
- **HIG:** Layout; Typography.
- **What happens:** The fixed width is right for the exported image, but the on-screen preview is a narrow strip on iPad. At large text sizes the 54 pt zone cells plus `minimumScaleFactor(0.7)` shrink labels instead of reflowing.
- **Suggested fix:** Keep 320 pt only for `ImageRenderer`. Let the preview scale (`.scaleEffect` to fit) or render the card adaptively on screen. Pin `.dynamicTypeSize(.large)` on the export only.

### F-19 · Medium · Section titles are not headings

- **Evidence:** `Features/Teams/RosterEditorView.swift:283`, `Features/ShooterCard/ShooterCardContentView.swift:131`, `Insights/PatternsSection.swift` and similar (`Text(...).font(.headline)` with no trait). No file in the app target uses `.isHeader`.
- **HIG:** Accessibility — VoiceOver users navigate long screens by headings.
- **Suggested fix:** Add `.accessibilityAddTraits(.isHeader)` to section titles. A tiny `SectionTitle` view in `DesignSystem` would keep it consistent.

### F-20 · Low · New session sheet order

- **Evidence:** `Features/Sessions/NewSessionSheet.swift:40` — the roster lists come first; Kind and Match Date sit at the bottom of a long form.
- **HIG:** Forms — put the most important, always-needed fields first.
- **Suggested fix:** Put Kind and Date first, then the rosters, possibly collapsed under a "Players (14)" disclosure.

### F-21 · Low · "Effectiveness / Save rate" is ambiguous

- **Evidence:** `iphone-en-light-scouting-demo.png`; `Features/Scouting/TeamScoutingView.swift`. "Save rate" reads the own team's shots against the rival goalkeeper; the segment doesn't say whose.
- **Suggested fix:** Use "Their shooters / Their goalkeeper" or "Attack / Goalkeeper" labels with a one-line caption.

### F-22 · Low · Weak hierarchy on cards

- **Evidence:** `Features/ShooterCard/ShooterCardView.swift:43` (title "Shooter"), `Insights/InsightTextView.swift:18`, `Features/ShooterCard/ShooterCardContentView.swift:131` (the whole section, heading included, is `.secondary`).
- **Suggested fix:** Title the screen with the player ("#3 Jordi Ferrer") and drop the duplicate header. Render the insight sentence in `.primary`, since it is the card's key takeaway. Keep section headings primary.

### F-23 · Low · Shot log idioms

- **Evidence:** `Features/Sessions/ShotLogView.swift:77` (`Done` as `.cancellationAction`, leading), `:62` (delete only by swipe).
- **Suggested fix:** Use `.confirmationAction` for Done, and add `EditButton()` so deletion is discoverable. Summaries use monospaced coded text ("… · POST"); consider plain sentences with an outcome icon.

### F-24 · Low · Own team roster is a hand-built form

- **Evidence:** `Features/Teams/OwnTeamRosterView.swift:26` — `ScrollView` + `.roundedBorder` field + prominent button. Every other editor is a `Form`. The name error appears under the roster, far from the field. Archived own players are not tappable, unlike rival ones.
- **Suggested fix:** Use a `Form` section for the name, with inline validation, and keep the grid below it.

### F-25 · Low · Breakdown chart fixed widths

- **Evidence:** `DesignSystem/OutcomeBreakdownChart.swift:63` (52 pt name column), `:103` (black count text on green/orange/gray).
- **Suggested fix:** Use a `Grid` with flexible columns or Swift Charts' `BarMark` with annotations. Choose the label colour per segment.

### F-26 · Low · Copy consistency

- **Evidence:** `Features/Teams/TeamsView.swift:91` ("My club", sentence case) next to "Own Team Roster" (title case). `MyClubView.swift:14` repeats "My club" as the empty-state title. "Scouting" stays English in es / es-419 (a deliberate loanword?).
- **Suggested fix:** Pick title case for menu items and titles (the HIG default on iOS). Name the two own-team entries as one concept ("My Club" → Roster / Stats). Confirm the "Scouting" choice.

### F-27 · Low · 7 m stat line is hard to scan

- **Evidence:** `Features/Scouting/SevenMeterSection.swift:20` — "Attempts: · Goals: · Saves: · Posts: · Out:" as one wrapping line.
- **Suggested fix:** Use a small `Grid` or `LabeledContent` rows, or reuse `OutcomeBreakdownChart`.

## Liquid Glass and iOS 26 notes

- The app already gets Liquid Glass for free in toolbars, nav bars and sheets (visible in the grouped toolbar buttons). Nothing custom fights it.
- Opportunities: the entry overlay in F-01 (`.glassEffect` on the bottom inset), selected chips as `.glassProminent` (F-11), `.navigationSubtitle` (F-13), and `ToolbarSpacer` to separate Scouting from New Session in the roster toolbar. Two icon-only buttons (`chart.bar.xaxis`, `plus.circle`) next to each other are easy to confuse; the sidebar already uses `plus` for "New Team".

## Not verified in this pass

- VoiceOver navigation order and spoken output (code-reviewed only).
- iPad landscape (three-column entry) and Split View / Stage Manager sizes.
- Increase Contrast, Reduce Transparency, Bold Text and Button Shapes settings.
- Sheets beyond what the code shows (roster sheet, new session sheet, edit player); these were reviewed in code, not captured.
- es-419 was captured only at AX3; en and es at the default size.

## Suggested task order

1. F-03, F-02, F-07, F-08 — quick, high-value fixes (colours, a `#if DEBUG`, an icon).
2. F-01 + F-13 + F-10 + F-11 + F-12 — one "shot entry ergonomics" task.
3. F-04, F-16, F-15, F-14 — empty and confirmation states.
4. F-05, F-09, F-18, F-19 + a UI test using `performAccessibilityAudit()` — one Dynamic Type and VoiceOver task.
5. F-17 — iPad layout pass, including landscape verification.
6. The Low items as polish.

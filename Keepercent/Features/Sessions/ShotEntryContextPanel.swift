// ShotEntryContextPanel draws the right-hand context column of shot entry
// (T3.3 decision ③): the sticky attacking-side toggle, the persistent
// active rival goalkeeper picker, the optional delivery/approach chips, the
// pending goal/saved question, an inline validation message, and the
// last-shot card with Undo.
//
// PRESENTATIONAL per CLAUDE.md: every value in is a plain
// `KeepercentDomain` value or primitive, every action out is a closure —
// no SwiftData, no `ModelContext`. `SessionView` (the container) owns every
// `@State` this panel reflects and every domain call its closures trigger.
//
// The `Binding(get:set:)` wrapping around `Picker`'s selection is the same
// pattern `RosterEditorView` already uses for its alerts: it lets a
// genuinely presentational view (no `@State` of its own) still drive a
// SwiftUI control that wants a two-way binding, without promoting the
// underlying value to a `@Binding` the container would have to expose.

import SwiftUI
import KeepercentDomain

struct ShotEntryContextPanel: View {
    let attackingSide: AttackingSide
    let onSelectAttackingSide: (AttackingSide) -> Void

    /// Only this team's goalkeepers (`Player.isGoalkeeper`), per T3.3's
    /// decision: the active rival goalkeeper is picked from among them,
    /// never a free number.
    let goalkeepers: [Player]
    let activeGoalkeeperNumber: Int?
    let onSelectGoalkeeper: (Int) -> Void

    let delivery: ShotDelivery?
    let onToggleDelivery: (ShotDelivery) -> Void
    let approach: ShotApproach?
    let onToggleApproach: (ShotApproach) -> Void

    /// True once a tap on `GoalView` resolved to an inside-the-frame target
    /// (`GoalTarget.impliedOutcome == nil`): a post or a miss never reaches
    /// this state, since `SessionView` records those immediately.
    let showsOutcomeQuestion: Bool
    let onChooseOutcome: (ShotOutcome) -> Void

    /// The message from `shotEntryErrorMessage`, shown inline — T3.3
    /// explicitly asks for this INSTEAD of an alert, since shot entry is
    /// live and rapid-fire; an alert would force a dismissal tap between
    /// every mis-tap and the next attempt.
    let errorMessage: String?

    /// `nil` until the first shot of this session is recorded, or after the
    /// undo card's own ~2 s auto-dismiss (owned by `SessionView`, not this
    /// view — see `LastShotCardView`'s header comment).
    let lastShotCard: LastShotCardState?
    let onUndo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker(
                "Attacking Side",
                selection: Binding(get: { attackingSide }, set: { onSelectAttackingSide($0) })
            ) {
                Text("Rival").tag(AttackingSide.rival)
                Text("Own").tag(AttackingSide.own)
            }
            .pickerStyle(.segmented)

            activeGoalkeeperSection
            chipsSection

            if showsOutcomeQuestion {
                outcomeQuestion
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(Color(.systemRed))
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }

            Spacer(minLength: 0)

            if let lastShotCard {
                LastShotCardView(state: lastShotCard, onUndo: onUndo)
            }
        }
        .animation(.default, value: errorMessage)
    }

    // MARK: - Sections

    /// "Shown at the top of the context panel" per T3.3's decision — placed
    /// right under the attacking-side toggle, since it is the second piece
    /// of state that persists across shots and is needed before an
    /// own-team attack can be recorded at all.
    private var activeGoalkeeperSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Active Rival Goalkeeper")
                .font(.caption)
                .foregroundStyle(.secondary)

            if goalkeepers.isEmpty {
                Text("No goalkeeper marked on this roster yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Picker(
                    "Active Rival Goalkeeper",
                    selection: Binding(
                        get: { activeGoalkeeperNumber },
                        set: { number in if let number { onSelectGoalkeeper(number) } }
                    )
                ) {
                    Text("None").tag(Int?.none)
                    ForEach(goalkeepers, id: \.number) { goalkeeper in
                        Text("#\(goalkeeper.number)\(goalkeeper.name.map { " \($0)" } ?? "")")
                            .tag(Int?.some(goalkeeper.number))
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var chipsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Delivery")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    chip("Jump", isSelected: delivery == .jump) { onToggleDelivery(.jump) }
                    chip("Standing", isSelected: delivery == .standing) { onToggleDelivery(.standing) }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Approach")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    chip("From Left", isSelected: approach == .fromLeft) { onToggleApproach(.fromLeft) }
                    chip("Straight", isSelected: approach == .straight) { onToggleApproach(.straight) }
                    chip("From Right", isSelected: approach == .fromRight) { onToggleApproach(.fromRight) }
                }
            }
        }
    }

    /// "Two large buttons Goal / Saved" per T3.3's decision — full-width and
    /// bold, since this is the one question every inside-the-frame shot
    /// must answer before it can be recorded at all.
    private var outcomeQuestion: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Goal or saved?")
                .font(.headline)
            HStack(spacing: 12) {
                Button("Goal") { onChooseOutcome(.goal) }
                    .tint(.green)
                Button("Saved") { onChooseOutcome(.saved) }
                    .tint(.orange)
            }
            .buttonStyle(.borderedProminent)
            .font(.title3.bold())
            .frame(maxWidth: .infinity)
        }
    }

    /// A chip that toggles: tapping the already-selected chip clears it
    /// (T3.3 decision, "tap again to clear") — `SessionView` owns that
    /// comparison (`delivery == value ? nil : value`), this view only
    /// reports which chip was tapped.
    private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .bold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color.accentColor.opacity(0.22) : Color(.tertiarySystemFill),
                    in: Capsule()
                )
                .overlay {
                    Capsule().stroke(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview("ShotEntryContextPanel") {
    ShotEntryContextPanel(
        attackingSide: .rival,
        onSelectAttackingSide: { _ in },
        goalkeepers: [Player(number: 12, name: "Sofía", isGoalkeeper: true, handedness: .right)],
        activeGoalkeeperNumber: 12,
        onSelectGoalkeeper: { _ in },
        delivery: .jump,
        onToggleDelivery: { _ in },
        approach: nil,
        onToggleApproach: { _ in },
        showsOutcomeQuestion: true,
        onChooseOutcome: { _ in },
        errorMessage: nil,
        lastShotCard: .recorded(text: "#7 · left back · crossbar center · POST"),
        onUndo: {}
    )
    .padding()
    .frame(width: 320)
}

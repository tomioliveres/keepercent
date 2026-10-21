// Presentational controls shared by the portrait inset and landscape column.
// SessionView owns every selection, write, feedback event and Undo identity.
import SwiftUI
import KeepercentDomain

struct ShotEntryContextPanel: View {
    let attackingSide: AttackingSide
    let onSelectAttackingSide: (AttackingSide) -> Void
    let goalkeepers: [Player]
    let activeGoalkeeperNumber: Int?
    let onSelectGoalkeeper: (Int) -> Void
    let delivery: ShotDelivery?
    let onToggleDelivery: (ShotDelivery) -> Void
    let approach: ShotApproach?
    let onToggleApproach: (ShotApproach) -> Void
    let progress: ShotEntryProgress
    let selectedOutcome: ShotOutcome?
    let target: GoalTarget?
    let onChooseOutcome: (ShotOutcome) -> Void
    let errorMessage: String?
    let lastShotCard: LastShotCardState?
    let onUndo: () -> Void
    let ownGoalkeepers: [Player]
    let ownGoalkeeperID: UUID?
    let onSelectOwnGoalkeeper: (UUID?) -> Void

    var body: some View {
        VStack(spacing: 12) {
            participants
            Spacer(minLength: 0)
            feedback
        }
    }

    /// Selection is never cleared by hiding a picker. Rival and optional own
    /// goalkeeper associations remain separate, with their original meaning.
    var participants: some View {
        HStack(spacing: 8) {
            Picker("Attacking Side", selection: Binding(
                get: { attackingSide }, set: { onSelectAttackingSide($0) }
            )) {
                Text("Rival").tag(AttackingSide.rival)
                Text("Own").tag(AttackingSide.own)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 180)

            if attackingSide == .own {
                Picker("Active Rival Goalkeeper", selection: Binding(
                    get: { activeGoalkeeperNumber },
                    set: { if let number = $0 { onSelectGoalkeeper(number) } }
                )) {
                    Text("None").tag(Int?.none)
                    ForEach(goalkeepers, id: \.number) { player in
                        Text(verbatim: "#\(player.number)\(player.name.map { " \($0)" } ?? "")")
                            .tag(Int?.some(player.number))
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accessibilityLabel("Active Rival Goalkeeper")
            } else {
                Picker("Own Goalkeeper (optional)", selection: Binding(
                    get: { ownGoalkeeperID }, set: { onSelectOwnGoalkeeper($0) }
                )) {
                    Text("None").tag(UUID?.none)
                    ForEach(ownGoalkeepers, id: \.id) { player in
                        Text(verbatim: "#\(player.number)\(player.name.map { " \($0)" } ?? "")")
                            .tag(player.id)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accessibilityLabel("Own Goalkeeper (optional)")
            }
        }
        .frame(minHeight: 44)
    }

    /// The same fixed-height surface occupies the portrait safe-area inset
    /// and the landscape context column. Card/error transitions never resize it.
    var feedback: some View {
        VStack(spacing: 6) {
            Group {
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(Palette.error)
                        .lineLimit(2).accessibilityLabel(errorMessage)
                } else {
                    steps
                }
            }
            .font(.caption)
            .frame(height: 32)

            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    chip("Jump", accessibilityLabel: "Jump", selected: delivery == .jump) { onToggleDelivery(.jump) }
                    chip("Standing", accessibilityLabel: "Standing", selected: delivery == .standing) { onToggleDelivery(.standing) }
                    chip("←", accessibilityLabel: "From Left", selected: approach == .fromLeft) { onToggleApproach(.fromLeft) }
                    chip("↑", accessibilityLabel: "Straight", selected: approach == .straight) { onToggleApproach(.straight) }
                    chip("→", accessibilityLabel: "From Right", selected: approach == .fromRight) { onToggleApproach(.fromRight) }
                }
            }
            .scrollIndicators(.hidden)
            .frame(height: 44)

            actionSlot.frame(height: 64)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .frame(height: 172)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    private var steps: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                if attackingSide == .rival { step("Shooter", .shooter) }
                else { step("Active Rival Goalkeeper", .rivalGoalkeeper) }
                step("Origin", .origin)
                step("Target", .target)
                if target != nil && target?.impliedOutcome == nil { step("Outcome", .outcome) }
            }
        }
        .scrollIndicators(.hidden)
        .accessibilityElement(children: .combine)
    }

    private func step(_ title: LocalizedStringKey, _ step: ShotEntryProgress.Step) -> some View {
        HStack(spacing: 3) {
            Text(title)
            if !progress.missingSteps.contains(step) {
                Image(systemName: "checkmark").foregroundStyle(Palette.accent)
            }
        }
    }

    @ViewBuilder private var actionSlot: some View {
        if let lastShotCard {
            switch lastShotCard {
            case .recorded(let text):
                HStack(spacing: 8) {
                    Text(text).font(.caption).lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel(text)
                    Button("Undo", action: onUndo)
                        .buttonStyle(.borderedProminent).tint(Palette.destructive)
                        .frame(minHeight: 44)
                }
            case .removed:
                Text("Shot removed").foregroundStyle(.secondary)
            }
        } else {
            HStack(spacing: 12) {
                outcomeButton("Goal", .goal, symbol: "soccerball")
                outcomeButton("Saved", .saved, symbol: "hand.raised.fill")
            }
            .disabled(target?.impliedOutcome != nil)
        }
    }

    private func outcomeButton(_ title: LocalizedStringKey, _ outcome: ShotOutcome, symbol: String) -> some View {
        Button { onChooseOutcome(outcome) } label: {
            Label(title, systemImage: symbol).font(.headline)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .tint(selectedOutcome == outcome ? Palette.brandAmber : Color(.secondarySystemFill))
        .foregroundStyle(selectedOutcome == outcome ? Palette.onBrandAmber : .primary)
        .accessibilityAddTraits(selectedOutcome == outcome ? .isSelected : [])
    }

    private func chip(_ title: LocalizedStringKey, accessibilityLabel: LocalizedStringKey,
                      selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.subheadline.weight(selected ? .bold : .regular))
                .padding(.horizontal, 10).frame(minWidth: 44, minHeight: 44)
                .background(selected ? Palette.brandAmber : Color(.tertiarySystemFill), in: Capsule())
                .foregroundStyle(selected ? Palette.onBrandAmber : .primary)
                .overlay { Capsule().stroke(selected ? Palette.accent : .clear, lineWidth: 1.5) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

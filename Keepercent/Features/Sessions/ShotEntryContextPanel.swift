// Presentational controls shared by the portrait inset and landscape column.
// SessionView owns every selection, write, feedback event and Undo identity.
import SwiftUI
import KeepercentDomain

struct ShotEntryContextPanel: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            Picker("Attacking Side", selection: Binding(
                get: { attackingSide }, set: { onSelectAttackingSide($0) }
            )) {
                Text("Rival").tag(AttackingSide.rival)
                Text("Own").tag(AttackingSide.own)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : 180)

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

    /// Ordinary entry keeps its bottom panel; accessibility sizes place these
    /// controls in the screen's scroll content so text can grow without a cap.
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
            .frame(minHeight: 44)

            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) { chips }
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 6) { chips }
                }
                .scrollIndicators(.hidden)
                .frame(height: 44)
            }

            actionSlot.frame(minHeight: 64)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder private var chips: some View {
        chip("Jump", accessibilityLabel: "Jump", selected: delivery == .jump) { onToggleDelivery(.jump) }
        chip("Standing", accessibilityLabel: "Standing", selected: delivery == .standing) { onToggleDelivery(.standing) }
        chip("←", accessibilityLabel: "From Left", selected: approach == .fromLeft) { onToggleApproach(.fromLeft) }
        chip("↑", accessibilityLabel: "Straight", selected: approach == .straight) { onToggleApproach(.straight) }
        chip("→", accessibilityLabel: "From Right", selected: approach == .fromRight) { onToggleApproach(.fromRight) }
    }

    private var steps: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { stepLabels }
            VStack(alignment: .leading, spacing: 8) { stepLabels }
        }
        .accessibilityElement(children: .combine)
        .frame(minHeight: 44)
    }

    @ViewBuilder private var stepLabels: some View {
        if attackingSide == .rival { step("Shooter", .shooter) }
        else { step("Active Rival Goalkeeper", .rivalGoalkeeper) }
        step("Origin", .origin)
        step("Target", .target)
        if target != nil && target?.impliedOutcome == nil { step("Outcome", .outcome) }
    }

    private func step(_ title: LocalizedStringKey, _ step: ShotEntryProgress.Step) -> some View {
        HStack(spacing: 3) {
            Text(title)
                .fixedSize(horizontal: false, vertical: true)
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
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 12))
                : AnyLayout(HStackLayout(spacing: 12))
            layout {
                outcomeButton("Goal", .goal, symbol: "soccerball")
                outcomeButton("Saved", .saved, symbol: "hand.raised.fill")
            }
            .disabled(target?.impliedOutcome != nil)
        }
    }

    private func outcomeButton(_ title: LocalizedStringKey, _ outcome: ShotOutcome, symbol: String) -> some View {
        Button { onChooseOutcome(outcome) } label: {
            Label(title, systemImage: symbol).font(.headline)
                .fixedSize(horizontal: false, vertical: true)
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
                .fixedSize()
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

import SwiftUI
import KeepercentDomain

/// Match selection edits value drafts only. Existing match facts are locked;
/// continuing an old match can deliberately add people, never rewrite them.
struct MatchRosterSelection: View {
    @Binding var players: [Player]
    var lockedIDs: Set<UUID> = []
    @State private var draft: MatchRosterDraft

    init(available: [Player], players: Binding<[Player]>, lockedIDs: Set<UUID> = []) {
        _players = players
        self.lockedIDs = lockedIDs
        _draft = State(initialValue: MatchRosterDraft(
            available: available, selected: players.wrappedValue, lockedIDs: lockedIDs))
    }

    var body: some View {
        Section {
            ForEach(draft.choices, id: \.id) { player in
                if let id = player.id {
                    let selected = draft.isSelected(id)
                    Toggle(isOn: Binding(get: { draft.isSelected(id) }, set: { included in
                        draft.setIncluded(included, for: id)
                        players = draft.selectedPlayers
                    })) {
                        HStack {
                            Text(verbatim: player.name ?? "#\(player.number)")
                            if player.isGoalkeeper { Text("Goalkeeper").font(.caption) }
                        }
                    }
                    .disabled(lockedIDs.contains(id))
                    // Keep this row present when deselected so later tap targets
                    // do not shift vertically. Resolve the draft by identity, not
                    // a captured array index that removal could invalidate.
                    HStack {
                        Text("Shirt Number")
                        if lockedIDs.contains(id) {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                        Spacer()
                        TextField("Number", value: Binding(
                            get: { draft.player(id: id)?.number ?? player.number },
                            set: { number in
                                draft.setNumber(number, for: id)
                                players = draft.selectedPlayers
                            }), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .accessibilityLabel("Shirt Number")
                    }
                    .disabled(!selected || lockedIDs.contains(id))
                    .foregroundStyle(selected ? Color.primary : Color.secondary)
                    .opacity(selected ? 1 : 0.5)
                }
            }
        } header: {
            Text("Match roster")
        } footer: {
            Text("Only selected players belong to this match. Later club roster edits do not change these snapshots.")
        }
    }
}

struct MatchRosterSheet: View {
    let available: [Player]
    @Binding var players: [Player]
    let lockedIDs: Set<UUID>
    let errorMessage: String?
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                MatchRosterSelection(available: available, players: $players, lockedIDs: lockedIDs)
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .navigationTitle("Match roster")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: onSave) }
            }
        }
    }
}

import SwiftUI
import KeepercentDomain

/// Match selection edits value drafts only. Existing match facts are locked;
/// continuing an old match can deliberately add people, never rewrite them.
struct MatchRosterSelection: View {
    @Binding var players: [Player]
    var lockedIDs: Set<UUID> = []
    @State private var choices: [Player]

    init(available: [Player], players: Binding<[Player]>, lockedIDs: Set<UUID> = []) {
        _players = players
        self.lockedIDs = lockedIDs
        let initial = players.wrappedValue
        let ids = Set(initial.compactMap(\.id))
        // Capture suggested order once per presentation, with existing snapshots
        // taking precedence. Selection and editable numbers never reorder rows.
        let choices = initial + available.filter { player in
            guard let id = player.id else { return false }
            return !ids.contains(id)
        }
        _choices = State(initialValue: choices.sorted {
            if $0.number != $1.number { return $0.number < $1.number }
            return ($0.id?.uuidString ?? "") < ($1.id?.uuidString ?? "")
        })
    }

    var body: some View {
        Section {
            ForEach(choices, id: \.id) { player in
                if let id = player.id {
                    let selected = players.contains { $0.id == id }
                    Toggle(isOn: Binding(get: { selected }, set: { included in
                        if included { players.append(player) } else { players.removeAll { $0.id == id } }
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
                        Spacer()
                        TextField("Number", value: Binding(
                            get: { players.first { $0.id == id }?.number ?? player.number },
                            set: { number in
                                guard let index = players.firstIndex(where: { $0.id == id }) else { return }
                                let old = players[index]
                                players[index] = Player(id: id, number: number, name: old.name,
                                                        isGoalkeeper: old.isGoalkeeper, handedness: old.handedness)
                            }), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .accessibilityLabel("Shirt Number")
                    }
                    .disabled(!selected || lockedIDs.contains(id))
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

import SwiftUI
import KeepercentDomain

/// Match selection edits value drafts only. Existing match facts are locked;
/// continuing an old match can deliberately add people, never rewrite them.
struct MatchRosterSelection: View {
    @Binding var players: [Player]
    var lockedIDs: Set<UUID> = []
    var title: LocalizedStringKey = "Match roster"
    @State private var draft: MatchRosterDraft
    @State private var editingID: UUID?
    @State private var numberText = ""

    init(available: [Player], players: Binding<[Player]>, lockedIDs: Set<UUID> = [],
         title: LocalizedStringKey = "Match roster") {
        _players = players
        self.lockedIDs = lockedIDs
        self.title = title
        _draft = State(initialValue: MatchRosterDraft(
            available: available, selected: players.wrappedValue, lockedIDs: lockedIDs))
    }

    var body: some View {
        Section {
            if draft.choices.isEmpty {
                Text("No players available. Add players to the club roster first.")
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    Button("Select All") { setAllIncluded(true) }
                    Spacer()
                    Button("Select None") { setAllIncluded(false) }
                }
                .buttonStyle(.borderless)
                .disabled(draft.choices.allSatisfy { $0.id.map(lockedIDs.contains) ?? true })
            }
            ForEach(draft.choices, id: \.id) { player in
                if let id = player.id {
                    let current = draft.player(id: id) ?? player
                    if lockedIDs.contains(id) {
                        HStack {
                            playerLabel(current)
                            Spacer()
                            Label("Locked", systemImage: "lock.fill").font(.caption)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityHint("Already belongs to this match. Inclusion and shirt number cannot be changed.")
                    } else {
                        HStack {
                            Toggle(isOn: Binding(get: { draft.isSelected(id) }, set: { included in
                                draft.setIncluded(included, for: id)
                                players = draft.selectedPlayers
                            })) {
                                playerLabel(current)
                            }
                            Button {
                                numberText = String(current.number)
                                editingID = id
                            } label: {
                                Image(systemName: "pencil").frame(minWidth: 44, minHeight: 44)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Edit shirt number for \(current.name ?? "#\(current.number)")")
                            .disabled(!draft.isSelected(id))
                        }
                    }
                }
            }
        } header: {
            Text(title)
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Only selected players belong to this match. Later club roster edits do not change these snapshots.")
                if !lockedIDs.isEmpty {
                    Label("Locked players already belong to this match. Their inclusion and shirt numbers cannot be changed.",
                          systemImage: "lock.fill")
                }
            }
        }
        .alert("Shirt Number", isPresented: Binding(
            get: { editingID != nil }, set: { if !$0 { editingID = nil } }
        ), presenting: editingID) { id in
            TextField("Number", text: $numberText).keyboardType(.numberPad)
            Button("Save") {
                if let number = Int(numberText) {
                    draft.setNumber(number, for: id)
                    players = draft.selectedPlayers
                }
                editingID = nil
            }
            .disabled(Int(numberText) == nil)
            Button("Cancel", role: .cancel) { editingID = nil }
        }
    }

    private func playerLabel(_ player: Player) -> some View {
        VStack(alignment: .leading) {
            Text(verbatim: "#\(player.number)" + (player.name.map { " · \($0)" } ?? ""))
            if player.isGoalkeeper { Text("Goalkeeper").font(.caption).foregroundStyle(.secondary) }
        }
    }

    private func setAllIncluded(_ included: Bool) {
        for player in draft.choices {
            if let id = player.id { draft.setIncluded(included, for: id) }
        }
        players = draft.selectedPlayers
    }
}

/// Always keep the selection view alive when skipping, so turning the own
/// team off/on cannot discard a deselected player's edited number draft.
struct OwnMatchRosterSelection: View {
    let teamName: String?
    let available: [Player]
    @Binding var included: Bool
    @Binding var players: [Player]
    var lockedIDs: Set<UUID> = []
    var isAttached = false

    var body: some View {
        Section("Own Team (optional)") {
            if let teamName {
                Picker("Own Team (optional)", selection: $included) {
                    Text("None").tag(false)
                    Text(verbatim: teamName).tag(true)
                }
                .disabled(isAttached)
            } else {
                Text("No own team configured. You can continue without one.")
            }
        }
        if teamName != nil {
            MatchRosterSelection(available: available, players: $players, lockedIDs: lockedIDs,
                                 title: "Own match roster")
                .disabled(!included)
        }
    }
}

struct MatchRosterSheet: View {
    let available: [Player]
    @Binding var players: [Player]
    let lockedIDs: Set<UUID>
    let errorMessage: String?
    let onSave: () -> Void
    let ownTeamName: String?
    let ownAvailable: [Player]
    @Binding var includeOwn: Bool
    @Binding var ownPlayers: [Player]
    let ownLockedIDs: Set<UUID>
    let ownIsAttached: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                MatchRosterSelection(available: available, players: $players, lockedIDs: lockedIDs)
                OwnMatchRosterSelection(teamName: ownTeamName, available: ownAvailable,
                                        included: $includeOwn, players: $ownPlayers,
                                        lockedIDs: ownLockedIDs, isAttached: ownIsAttached)
                if let errorMessage { Text(errorMessage).foregroundStyle(Palette.error) }
            }
            .navigationTitle("Match roster")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: onSave) }
            }
        }
    }
}

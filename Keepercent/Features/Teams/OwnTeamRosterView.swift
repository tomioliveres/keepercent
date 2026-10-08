import SwiftUI
import SwiftData
import KeepercentDomain

/// Own roster container: one optional configured club, no cross-opponent cards.
/// Reuses the value-only player editors; all identity-preserving writes live here.
struct OwnTeamRosterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \StoredOwnTeam.createdAt) private var clubs: [StoredOwnTeam]
    @State private var name = ""
    @State private var errorMessage: String?
    @State private var editingPlayer: StoredPlayer?
    @State private var isAdding = false
    @State private var addError: String?

    private var club: StoredOwnTeam? { clubs.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Own team is optional. Rival-only scouting remains available.")
                        .foregroundStyle(.secondary)
                    TextField("Team name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    Button(action: saveName) {
                        Text(club == nil ? LocalizedStringKey("Configure Own Team") : LocalizedStringKey("Save"))
                    }
                        .buttonStyle(.borderedProminent)
                    if let club {
                        rosterContent(club)
                    }
                    if let errorMessage {
                        Text(errorMessage).foregroundStyle(Palette.error)
                    }
                }
                .padding()
            }
            .navigationTitle("Own Team Roster")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .onAppear { name = club?.name ?? "" }
            .sheet(item: $editingPlayer) { stored in
                PlayerEditorView(player: stored.domainPlayer,
                                 shotCount: stored.ownShotsTaken.count + stored.ownShotsFaced.count,
                                 onSave: { update(stored, to: $0) }, onDelete: { archive(stored) })
                    .alert("Couldn't Complete Action", isPresented: Binding(
                        get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                        Button("OK", role: .cancel) { errorMessage = nil }
                    } message: { Text(errorMessage ?? "") }
            }
            .sheet(isPresented: $isAdding) {
                AddUnknownPlayerView(allowedRange: Roster.numberRange, errorMessage: addError, onAdd: add)
            }
        }
    }

    @ViewBuilder private func rosterContent(_ club: StoredOwnTeam) -> some View {
        switch Result(catching: { try Roster(players: club.players.filter { $0.archivedAt == nil }.map(\.domainPlayer)) }) {
        case .success(let roster):
            RosterGridView(players: roster.players,
                           onSelectPlayer: { edit($0) }, onEditPlayer: { edit($0) },
                           onTapAddUnknown: { addError = nil; isAdding = true }, isScrollable: false)
            let archived = club.players.filter { $0.archivedAt != nil }.sorted {
                if $0.number != $1.number { return $0.number < $1.number }
                return ($0.personID?.uuidString ?? "") < ($1.personID?.uuidString ?? "")
            }
            if !archived.isEmpty {
                Text("Archived players").font(.headline)
                ForEach(archived, id: \.persistentModelID) { player in
                    Text(verbatim: "#\(player.number) · \(player.name ?? "")")
                        .foregroundStyle(.secondary)
                }
            }
        case .failure(let error):
            Text(rosterErrorMessage(error)).foregroundStyle(Palette.error)
        }
    }

    private func edit(_ player: Player) {
        errorMessage = nil
        editingPlayer = club?.players.first { $0.personID == player.id }
    }

    private func saveName() {
        do {
            let validated = try RivalTeam(name: name)
            // Fetch at write time too, so another window's configuration does
            // not cause this stale screen to create a second own club.
            let existing = try modelContext.fetch(FetchDescriptor<StoredOwnTeam>()).first
            if let existing { existing.name = validated.name }
            else { modelContext.insert(StoredOwnTeam(name: validated.name)) }
            try modelContext.save()
            errorMessage = nil
        } catch {
            modelContext.rollback()
            errorMessage = rosterErrorMessage(error)
        }
    }

    private func add(number: Int) {
        guard let club else { return }
        do {
            let roster = try Roster(players: club.players.filter { $0.archivedAt == nil }.map(\.domainPlayer))
            _ = try roster.addUnknown(number: number)
            let stored = StoredPlayer(Player(number: number))
            club.players.append(stored)
            modelContext.insert(stored)
            try modelContext.save()
            isAdding = false
            addError = nil
        } catch {
            modelContext.rollback()
            addError = rosterErrorMessage(error)
        }
    }

    private func update(_ stored: StoredPlayer, to player: Player) {
        guard let club else { return }
        do {
            let roster = try Roster(players: club.players.filter { $0.archivedAt == nil }.map(\.domainPlayer))
            _ = try roster.update(number: stored.number, to: player)
            stored.number = player.number
            stored.name = player.name
            stored.isGoalkeeper = player.isGoalkeeper
            stored.handednessCode = player.handedness?.rawValue
            try modelContext.save()
            editingPlayer = nil
        } catch {
            modelContext.rollback()
            errorMessage = rosterErrorMessage(error)
        }
    }

    private func archive(_ stored: StoredPlayer) {
        do {
            stored.archivedAt = .now
            try modelContext.save()
            editingPlayer = nil
        } catch {
            modelContext.rollback()
            errorMessage = rosterErrorMessage(error)
        }
    }
}

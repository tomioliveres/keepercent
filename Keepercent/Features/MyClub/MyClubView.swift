import SwiftUI
import SwiftData
import KeepercentDomain

/// One own-club container for the roster and cross-opponent history.
/// Writes retain the original row-level validation and stable person identities.
struct MyClubView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredOwnTeam.createdAt) private var clubs: [StoredOwnTeam]
    @State private var name = ""
    @State private var errorMessage: String?
    @State private var isEditingName = false
    @State private var editingPlayer: StoredPlayer?
    @State private var isAdding = false
    @State private var addError: String?
    @State private var shooterRoute: OwnPlayerRoute?
    @State private var goalkeeperRoute: OwnPlayerRoute?

    private var club: StoredOwnTeam? { clubs.first }

    var body: some View {
        Group {
            if let club {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(club.name).font(.title2.bold())
                            .padding(.horizontal)
                        rosterContent(club)
                        clubHistory(club)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            } else {
                ContentUnavailableView {
                    Label("My Club", systemImage: "shield")
                } description: {
                    Text("No own team configured. You can continue without one.")
                } actions: {
                    Button("Set Up My Club") { editName() }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("My Club")
        .toolbar {
            if club != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: editName) { Label("Team name", systemImage: "pencil") }
                }
            }
        }
        .navigationDestination(item: $shooterRoute) { route in
            if let club { OwnShooterCardView(team: club, playerID: route.playerID) }
        }
        .navigationDestination(item: $goalkeeperRoute) { route in
            if let club { OwnGoalkeeperCardView(team: club, playerID: route.playerID) }
        }
        .sheet(isPresented: $isEditingName) {
            NavigationStack {
                Form {
                    Text("Own team is optional. Rival-only scouting remains available.")
                        .foregroundStyle(.secondary)
                    TextField("Team name", text: $name)
                    if let errorMessage { Text(errorMessage).foregroundStyle(Palette.error) }
                }
                .navigationTitle(club == nil ? String(localized: "Set Up My Club") : String(localized: "Team name"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isEditingName = false }
                    }
                    ToolbarItem(placement: .confirmationAction) { Button("Save", action: saveName) }
                }
            }
        }
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

    @ViewBuilder private func rosterContent(_ club: StoredOwnTeam) -> some View {
        switch Result(catching: { try Roster(players: club.players.filter { $0.archivedAt == nil }.map(\.domainPlayer)) }) {
        case .success(let roster):
            RosterGridView(players: roster.players,
                           onSelectPlayer: { player in
                               guard let id = player.id else { return }
                               if player.isGoalkeeper {
                                   goalkeeperRoute = OwnPlayerRoute(playerID: id)
                               } else {
                                   shooterRoute = OwnPlayerRoute(playerID: id)
                               }
                           }, onEditPlayer: edit,
                           onTapAddUnknown: { addError = nil; isAdding = true }, isScrollable: false)
            let archived = club.players.filter { $0.archivedAt != nil }.sorted {
                if $0.number != $1.number { return $0.number < $1.number }
                return ($0.personID?.uuidString ?? "") < ($1.personID?.uuidString ?? "")
            }
            if !archived.isEmpty {
                DisclosureGroup("Archived players") {
                    ForEach(archived, id: \.persistentModelID) { player in
                        Text(verbatim: "#\(player.number) · \(player.name ?? "")")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
            }
        case .failure(let error):
            Text(rosterErrorMessage(error)).foregroundStyle(Palette.error)
                .padding(.horizontal)
        }
    }

    /// Keep the former My Club inclusion rules: current roles plus any attributed
    /// history, including archived people and their previous playing roles.
    private func clubHistory(_ team: StoredOwnTeam) -> some View {
        let people = ScopedMatchData.people(team)
        let engine = ScopedMatchData.engine(team, scope: .all)
        let activeIDs = Set(team.players.filter { $0.archivedAt == nil }.compactMap(\.personID))
        let shooters = people.filter {
            guard let id = $0.id else { return false }
            return (activeIDs.contains(id) && !$0.isGoalkeeper) || !engine.shots(byOwnShooter: id).shots.isEmpty
        }
        let keepers = people.filter {
            guard let id = $0.id else { return false }
            return (activeIDs.contains(id) && $0.isGoalkeeper) || !engine.shots(facingOwnGoalkeeper: id).shots.isEmpty
        }
        return VStack(alignment: .leading, spacing: 16) {
            Text("Own player statistics across opponents")
                .font(.headline)
            if shooters.isEmpty && keepers.isEmpty {
                ContentUnavailableView("No own player data", systemImage: "chart.bar.xaxis",
                    description: Text("No attributed own-player history is available yet."))
            }
            if !shooters.isEmpty {
                Text("Shooter").font(.headline)
                ForEach(shooters, id: \.id) { player in
                    if let id = player.id {
                        Button { shooterRoute = OwnPlayerRoute(playerID: id) } label: { personLabel(player) }
                            .buttonStyle(.plain)
                    }
                }
            }
            if !keepers.isEmpty {
                Text("Goalkeeper").font(.headline)
                ForEach(keepers, id: \.id) { player in
                    if let id = player.id {
                        Button { goalkeeperRoute = OwnPlayerRoute(playerID: id) } label: { personLabel(player) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func personLabel(_ player: Player) -> some View {
        HStack {
            Text(verbatim: player.name.map { "#\(player.number) · \($0)" } ?? "#\(player.number)")
                .font(.headline)
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary).accessibilityHidden(true)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private func editName() {
        name = club?.name ?? ""
        errorMessage = nil
        isEditingName = true
    }

    private func edit(_ player: Player) {
        errorMessage = nil
        editingPlayer = club?.players.first { $0.personID == player.id }
    }

    // Existing own-roster write operations, moved here without replacing rows.
    private func saveName() {
        do {
            let validated = try RivalTeam(name: name)
            // Fetch at write time too: another window may have configured a club.
            let existing = try modelContext.fetch(FetchDescriptor<StoredOwnTeam>()).first
            if let existing { existing.name = validated.name }
            else { modelContext.insert(StoredOwnTeam(name: validated.name)) }
            try modelContext.save()
            errorMessage = nil
            isEditingName = false
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

private struct OwnPlayerRoute: Hashable {
    let playerID: UUID
}

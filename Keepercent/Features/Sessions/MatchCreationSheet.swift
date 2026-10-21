import SwiftUI
import SwiftData
import KeepercentDomain

/// Both entry points use the same domain validation and snapshot-preserving save.
struct MatchCreationSheet: View {
    var rival: StoredRivalTeam?
    let onCreated: (StoredSession) -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \StoredRivalTeam.name) private var rivals: [StoredRivalTeam]
    @Query(sort: \StoredOwnTeam.createdAt) private var ownTeams: [StoredOwnTeam]
    @State private var selectedRival: StoredRivalTeam?

    var body: some View {
        Group {
            if let team = rival ?? selectedRival {
                MatchCreationForm(team: team, ownTeam: ownTeams.first, onStart: start)
                    .id(team.persistentModelID)
            } else {
                NavigationStack {
                    List(rivals) { team in
                        Button(team.name) { selectedRival = team }
                    }
                    .overlay {
                        if rivals.isEmpty {
                            ContentUnavailableView("No Rivals", systemImage: "person.3",
                                description: Text("Add a team in Rivals before starting a match."))
                        }
                    }
                    .navigationTitle("Choose Rival")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { dismiss() }
                        }
                    }
                }
            }
        }
    }

    /// Validation precedes insertion. Failure rolls back all tentative rows,
    /// preserving the original sessions, roster identities and shot links.
    private func start(team: StoredRivalTeam, kind: SessionKind, date: Date,
                       players: [Player], ownPlayers: [Player], includeOwn: Bool) throws {
        do {
            let session = try Session(kind: kind, matchDate: date, today: .now, calendar: .current)
            let roster = try MatchRoster(players: players)
            let stored = StoredSession(date: session.matchDate, kindCode: session.kind.rawValue, rivalTeam: team)
            stored.participants = roster.players.map(StoredMatchParticipant.init)
            if includeOwn, let ownTeam = ownTeams.first {
                let ownRoster = try MatchRoster(players: ownPlayers)
                stored.ownTeam = ownTeam
                stored.ownParticipants = ownRoster.players.map(StoredMatchParticipant.init)
            }
            team.sessions.append(stored)
            modelContext.insert(stored)
            try modelContext.save()
            onCreated(stored)
            dismiss()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}

/// Draft state is initialized once per chosen rival, never reset by body updates.
private struct MatchCreationForm: View {
    let team: StoredRivalTeam
    let ownTeam: StoredOwnTeam?
    let onStart: (StoredRivalTeam, SessionKind, Date, [Player], [Player], Bool) throws -> Void
    @State private var kind: SessionKind = .live
    @State private var date: Date = .now
    @State private var players: [Player]
    @State private var ownPlayers: [Player]
    @State private var includeOwn: Bool
    @State private var errorMessage: String?

    init(team: StoredRivalTeam, ownTeam: StoredOwnTeam?,
         onStart: @escaping (StoredRivalTeam, SessionKind, Date, [Player], [Player], Bool) throws -> Void) {
        self.team = team
        self.ownTeam = ownTeam
        self.onStart = onStart
        _players = State(initialValue: team.players.filter { $0.archivedAt == nil }.map(\.domainPlayer))
        _ownPlayers = State(initialValue: ownTeam?.players.filter { $0.archivedAt == nil }.map(\.domainPlayer) ?? [])
        _includeOwn = State(initialValue: ownTeam != nil)
    }

    var body: some View {
        NewSessionSheet(kind: $kind, matchDate: $date, onStart: {
            do {
                try onStart(team, kind, date, players, ownPlayers, includeOwn)
            } catch {
                errorMessage = error is RosterError ? rosterErrorMessage(error) : sessionErrorMessage(error)
            }
        }, available: team.players.filter { $0.archivedAt == nil }.map(\.domainPlayer),
           participants: $players, ownTeamName: ownTeam?.name,
           ownAvailable: ownTeam?.players.filter { $0.archivedAt == nil }.map(\.domainPlayer) ?? [],
           includeOwn: $includeOwn, ownParticipants: $ownPlayers, rivalName: team.name)
        .alert("Couldn't Start Session", isPresented: Binding(
            get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }
}

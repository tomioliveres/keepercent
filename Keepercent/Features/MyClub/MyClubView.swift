import SwiftUI
import SwiftData
import KeepercentDomain

/// Read-only own-club history container. Roster editing remains a separate route.
struct MyClubView: View {
    @Query(sort: \StoredOwnTeam.createdAt) private var teams: [StoredOwnTeam]

    var body: some View {
        Group {
            if let team = teams.first {
                clubHistory(team)
            } else {
                ContentUnavailableView("My club", systemImage: "chart.bar.xaxis",
                                       description: Text("No own team configured. You can continue without one."))
            }
        }
        .navigationTitle("My club")
        .navigationBarTitleDisplayMode(.inline)
    }

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
        return List {
            Section {
                Text(team.name).font(.headline)
                Text("Own player statistics across opponents")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            if shooters.isEmpty && keepers.isEmpty {
                ContentUnavailableView("No own player data", systemImage: "chart.bar.xaxis",
                                       description: Text("No attributed own-player history is available yet."))
            }
            if !shooters.isEmpty {
                Section("Shooter") {
                    ForEach(shooters, id: \.id) { player in
                        if let id = player.id {
                            NavigationLink {
                                OwnShooterCardView(team: team, playerID: id)
                            } label: {
                                personLabel(player)
                            }
                        }
                    }
                }
            }
            if !keepers.isEmpty {
                Section("Goalkeeper") {
                    ForEach(keepers, id: \.id) { player in
                        if let id = player.id {
                            NavigationLink {
                                OwnGoalkeeperCardView(team: team, playerID: id)
                            } label: {
                                personLabel(player)
                            }
                        }
                    }
                }
            }
        }
    }

    private func personLabel(_ player: Player) -> some View {
        Text(verbatim: player.name.map { "#\(player.number) · \($0)" } ?? "#\(player.number)")
            .font(.headline)
    }
}

import SwiftUI
import KeepercentDomain

struct OwnShooterCardView: View {
    let team: StoredOwnTeam
    let playerID: UUID
    @State private var scope: MatchScope = .all

    private var player: Player? { ScopedMatchData.player(playerID, team: team, scope: scope) }
    private var engine: StatsEngine { ScopedMatchData.engine(team, scope: scope).shots(byOwnShooter: playerID) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                MatchScopePicker(options: ScopedMatchData.options(team), scope: $scope)
                if let player {
                    ShooterCardContentView(player: player, engine: engine).id(scope)
                } else {
                    ContentUnavailableView("No Shooter Data", systemImage: "chart.bar.xaxis",
                                           description: Text("No shots recorded yet"))
                }
            }
            .padding()
        }
        .navigationTitle("Shooter")
        .navigationBarTitleDisplayMode(.inline)
    }
}

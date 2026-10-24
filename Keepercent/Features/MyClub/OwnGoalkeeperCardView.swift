import SwiftUI
import KeepercentDomain

struct OwnGoalkeeperCardView: View {
    let team: StoredOwnTeam
    let playerID: UUID
    @State private var scope: MatchScope = .all

    private var player: Player? { ScopedMatchData.player(playerID, team: team, scope: scope) }
    private var engine: StatsEngine { ScopedMatchData.engine(team, scope: scope).shots(facingOwnGoalkeeper: playerID) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                MatchScopePicker(options: ScopedMatchData.options(team), scope: $scope)
                if let player {
                    GoalkeeperCardContentView(player: player, engine: engine).id(scope)
                } else {
                    ContentUnavailableView("No Goalkeeper Data", systemImage: "chart.bar.xaxis",
                                           description: Text("No shots faced yet").foregroundStyle(.primary))
                }
            }
            .padding()
        }
        .navigationTitle("Goalkeeper")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    TeamReportView(ownTeam: team, playerID: playerID, scope: scope)
                } label: {
                    Label("Team Report", systemImage: "square.and.arrow.up")
                }
                .disabled(player == nil || engine.shots.isEmpty)
            }
        }
    }
}

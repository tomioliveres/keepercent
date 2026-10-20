// GoalkeeperCardView is T4.4's CONTAINER, mirroring `ShooterCardView`'s own
// shape exactly (CLAUDE.md container/presentational split): it owns the
// SwiftData read (`team.sessions`) and narrows a fresh `StatsEngine` to one
// rival goalkeeper, matching `TeamScoutingView`'s own container. Its child
// `GoalkeeperCardContentView` only ever sees a `KeepercentDomain.Player`
// and a `StatsEngine`.
//
// Stable identity follows the goalkeeper through renumbering and archiving.

import SwiftUI
import KeepercentDomain

struct GoalkeeperCardView: View {
    let team: StoredRivalTeam
    let playerID: UUID
    @State private var scope: MatchScope = .all

    /// Scoped snapshot or all-match person; never a guessed number-only player.
    private var player: Player? {
        ScopedMatchData.player(playerID, team: team, scope: scope)
    }

    /// The selected match scope is retained before filtering by person identity.
    private var engine: StatsEngine {
        ScopedMatchData.engine(team, scope: scope).shots(facing: playerID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                MatchScopePicker(options: ScopedMatchData.options(team), scope: $scope)
                if let player {
                    GoalkeeperCardContentView(player: player, engine: engine).id(scope)
                } else {
                    ContentUnavailableView("No Goalkeeper Data", systemImage: "chart.bar.xaxis",
                                           description: Text("No rival goalkeeper has faced shots."))
                }
            }
            .padding()
        }
        // Same reasoning as `ShooterCardView`'s own bar title: the card's
        // header already shows "#1 · Name".
        .navigationTitle("Goalkeeper")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    TeamReportView(team: team, playerID: playerID, scope: scope)
                } label: {
                    Label("Team Report", systemImage: "doc.text.magnifyingglass")
                }
                // No attributable scoped attempts means no useful report.
                // Post/miss-only samples still count as data, not an empty card.
                .disabled(player == nil || engine.shots.isEmpty)
            }
        }
    }
}

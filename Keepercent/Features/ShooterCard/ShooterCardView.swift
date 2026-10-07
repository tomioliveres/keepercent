// ShooterCardView is T4.3's CONTAINER: it owns the SwiftData read
// (`team.sessions`) and narrows a fresh `StatsEngine` to one rival
// shooter, matching `TeamScoutingView`'s own container/presentational
// split (CLAUDE.md) — its child `ShooterCardContentView` only ever sees a
// `KeepercentDomain.Player` and a `StatsEngine`.
//
// Navigation and statistics use stable person identity. A single-match
// selection reads that match's snapshot, not today's mutable roster.

import SwiftUI
import KeepercentDomain

struct ShooterCardView: View {
    let team: StoredRivalTeam
    let playerID: UUID
    @State private var scope: MatchScope = .all

    /// Missing scoped participants remain absent; no number-based fallback.
    private var player: Player? {
        ScopedMatchData.player(playerID, team: team, scope: scope)
    }

    /// Scope first, then stable identity; shirt-number reuse cannot merge people.
    private var engine: StatsEngine {
        ScopedMatchData.engine(team, scope: scope).shots(by: playerID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                MatchScopePicker(options: ScopedMatchData.options(team), scope: $scope)
                if let player {
                    ShooterCardContentView(player: player, engine: engine).id(scope)
                } else {
                    ContentUnavailableView("No Shooter Data", systemImage: "chart.bar.xaxis",
                                           description: Text("No rival shooter has recorded shots."))
                }
            }
            .padding()
        }
        // The card's own header already shows "#7 · Name", so the bar
        // stays a small generic title instead of repeating the number.
        .navigationTitle("Shooter")
        .navigationBarTitleDisplayMode(.inline)
    }
}

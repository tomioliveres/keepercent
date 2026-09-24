// ShooterCardView is T4.3's CONTAINER: it owns the SwiftData read
// (`team.sessions`) and narrows a fresh `StatsEngine` to one rival
// shooter, matching `TeamScoutingView`'s own container/presentational
// split (CLAUDE.md) — its child `ShooterCardContentView` only ever sees a
// `KeepercentDomain.Player` and a `StatsEngine`.
//
// The shooter is identified by shirt number, the same match
// `StatsEngine.shots(by:)` already uses and `RosterEditorView` passes
// around for the roster's own edit/delete actions.

import SwiftUI
import KeepercentDomain

struct ShooterCardView: View {
    let team: StoredRivalTeam
    let playerNumber: Int

    /// The roster row for this shooter, or a bare, unnamed `Player` built
    /// from just the number if the row was somehow removed after this
    /// screen was pushed (e.g. deleted from another window on iPad) — the
    /// card still has shots to show even if the roster entry is gone.
    private var player: Player {
        team.players.first { $0.number == playerNumber }?.domainPlayer ?? Player(number: playerNumber)
    }

    /// Every shot recorded across this team's sessions, decoded from
    /// SwiftData exactly as `TeamScoutingView` does, then narrowed to this
    /// one shooter's own shots (`shots(by:)` already restricts to
    /// `.rival` shots from this shirt number).
    private var engine: StatsEngine {
        let shots = team.sessions.flatMap { $0.shots.compactMap(\.domainShot) }
        return StatsEngine(shots: shots).shots(by: playerNumber)
    }

    var body: some View {
        ScrollView {
            ShooterCardContentView(player: player, engine: engine)
                .padding()
        }
        // The card's own header already shows "#7 · Name", so the bar
        // stays a small generic title instead of repeating the number.
        .navigationTitle("Shooter")
        .navigationBarTitleDisplayMode(.inline)
    }
}

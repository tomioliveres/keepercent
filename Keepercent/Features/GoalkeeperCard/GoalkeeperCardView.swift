// GoalkeeperCardView is T4.4's CONTAINER, mirroring `ShooterCardView`'s own
// shape exactly (CLAUDE.md container/presentational split): it owns the
// SwiftData read (`team.sessions`) and narrows a fresh `StatsEngine` to one
// rival goalkeeper, matching `TeamScoutingView`'s own container. Its child
// `GoalkeeperCardContentView` only ever sees a `KeepercentDomain.Player`
// and a `StatsEngine`.
//
// The goalkeeper is identified by shirt number, the same match
// `StatsEngine.shots(facing:)` already uses.

import SwiftUI
import KeepercentDomain

struct GoalkeeperCardView: View {
    let team: StoredRivalTeam
    let playerNumber: Int

    /// The roster row for this goalkeeper, or a bare, unnamed `Player`
    /// built from just the number if the row was somehow removed after
    /// this screen was pushed — same fallback `ShooterCardView` uses.
    private var player: Player {
        team.players.first { $0.number == playerNumber }?.domainPlayer ?? Player(number: playerNumber)
    }

    /// Every shot recorded across this team's sessions, decoded from
    /// SwiftData exactly as `ShooterCardView` does, then narrowed to the
    /// shots this one goalkeeper faced (`shots(facing:)` already restricts
    /// to `.own` shots aimed at this shirt number).
    private var engine: StatsEngine {
        let shots = team.sessions.flatMap { $0.shots.compactMap(\.domainShot) }
        return StatsEngine(shots: shots).shots(facing: playerNumber)
    }

    var body: some View {
        ScrollView {
            GoalkeeperCardContentView(player: player, engine: engine)
                .padding()
        }
        // Same reasoning as `ShooterCardView`'s own bar title: the card's
        // header already shows "#1 · Name".
        .navigationTitle("Goalkeeper")
        .navigationBarTitleDisplayMode(.inline)
    }
}

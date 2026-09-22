// RosterGridView draws one rival team's roster as a grid of big numbered
// tiles (docs/mvp.md §6.1: "Roster as a grid of big numbered tiles,
// goalkeepers visually distinct"). PRESENTATIONAL per CLAUDE.md: it draws
// only the `[KeepercentDomain.Player]` it is given and reports taps
// through closures — no SwiftData import, no `StoredPlayer`.

import SwiftUI
import KeepercentDomain

struct RosterGridView: View {
    let players: [Player]
    let onSelectPlayer: (Player) -> Void
    let onTapAddUnknown: () -> Void

    /// Adaptive columns, each at least the roster tile's own minimum tap
    /// target, so the grid reflows from a narrow iPhone to a wide iPad
    /// split-view pane without ever shrinking a tile below 44x44.
    private let columns = [GridItem(.adaptive(minimum: rosterTileMinimumDimension + 32, maximum: 110), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(players, id: \.number) { player in
                    Button {
                        onSelectPlayer(player)
                    } label: {
                        PlayerTileView(player: player)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onTapAddUnknown) {
                    AddPlayerTileView()
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }
}

#Preview("RosterGridView") {
    RosterGridView(
        players: [
            Player(number: 1, name: "Marta", isGoalkeeper: true, handedness: .left),
            Player(number: 4, name: "Ana", isGoalkeeper: false, handedness: .right),
            Player(number: 7),
            Player(number: 12, name: "Sofía", isGoalkeeper: true, handedness: .right),
        ],
        onSelectPlayer: { _ in },
        onTapAddUnknown: {}
    )
}

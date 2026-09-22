// ShooterGridColumn draws the rival shooter grid for shot entry (T3.3,
// docs/mvp.md §6 item 3: "Shooter grid (rival numbers)"). It deliberately
// reuses `PlayerTileView` from Features/Teams rather than duplicating a
// numbered-tile drawing (goalkeepers already read as goalkeepers here too,
// for free), but it is NOT `RosterGridView`: that view always renders an
// "add unknown number" tile, which has no place during entry — an unknown
// number is added from the roster editor (T3.1's "+" tile), not mid-shot —
// and it has no notion of a currently selected player, which this grid
// needs so a tapped shooter stays visibly selected until the shot is
// recorded or the selection changes (T3.3 decision, "show the tapped
// selections highlighted").
//
// PRESENTATIONAL per CLAUDE.md: only `[KeepercentDomain.Player]` and a
// plain `Int?` in, a tap reported out — no SwiftData.

import SwiftUI
import KeepercentDomain

struct ShooterGridColumn: View {
    let players: [Player]
    let selectedNumber: Int?
    let onSelect: (Int) -> Void

    /// Same minimum as `RosterGridView`'s own grid (`rosterTileMinimumDimension`,
    /// Features/Teams/PlayerTileView.swift) — this is the same tap target,
    /// just without the "+" tile — capped a little tighter so more of a
    /// roster fits in one third of an iPad's width without scrolling.
    private let columns = [GridItem(.adaptive(minimum: rosterTileMinimumDimension + 20, maximum: 92), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(players, id: \.number) { player in
                Button {
                    onSelect(player.number)
                } label: {
                    PlayerTileView(player: player)
                        .overlay {
                            // A FILL, not a border: the heavy accent border is
                            // already how a goalkeeper tile is marked, so a
                            // selected shooter drawn with one looked like a
                            // third goalkeeper. A blue fill is also how
                            // GoalView and CourtView show their selection.
                            if selectedNumber == player.number {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(.systemBlue).opacity(0.3))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview("ShooterGridColumn") {
    ShooterGridColumn(
        players: [
            Player(number: 4, name: "Ana", isGoalkeeper: false, handedness: .right),
            Player(number: 7),
            Player(number: 12, name: "Sofía", isGoalkeeper: true, handedness: .right),
        ],
        selectedNumber: 7,
        onSelect: { _ in }
    )
    .padding()
}

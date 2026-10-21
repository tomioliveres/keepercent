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
    var isCompact = false

    /// Same minimum as `RosterGridView`'s own grid (`rosterTileMinimumDimension`,
    /// Features/Teams/PlayerTileView.swift) — this is the same tap target,
    /// just without the "+" tile — capped a little tighter so more of a
    /// roster fits in one third of an iPad's width without scrolling.
    private let columns = [GridItem(.adaptive(minimum: rosterTileMinimumDimension + 20, maximum: 92), spacing: 10)]

    var body: some View {
        if isCompact { compactStrip }
        else { grid }
    }

    private var compactStrip: some View {
        GeometryReader { proxy in
            let tileWidth = max(44, (proxy.size.width - 6 * 6) / 7)
            ScrollView(.horizontal) {
                LazyHGrid(rows: [GridItem(.fixed(44)), GridItem(.fixed(44))], spacing: 6) {
                    ForEach(orderedPlayers, id: \.number) { player in
                        Button { onSelect(player.number) } label: {
                            Text(verbatim: "\(player.number)")
                                .font(.headline.monospacedDigit())
                                .frame(width: tileWidth, height: 44)
                                .background(selectedNumber == player.number ? Palette.brandAmber : Color(.secondarySystemBackground),
                                            in: RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(selectedNumber == player.number ? Palette.onBrandAmber : .primary)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(player.isGoalkeeper || selectedNumber == player.number ? Palette.accent : .clear,
                                                lineWidth: 2)
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(verbatim: "#\(player.number)\(player.name.map { " \($0)" } ?? "")"))
                        .accessibilityValue(player.isGoalkeeper ? Text("Goalkeeper") : Text(""))
                        .accessibilityAddTraits(selectedNumber == player.number ? .isSelected : [])
                    }
                }
            }
            .scrollIndicators(.hidden)
            .overlay {
                if players.isEmpty {
                    Text("No players in this match roster.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 94)
    }

    private var orderedPlayers: [Player] {
        players.sorted {
            if $0.isGoalkeeper != $1.isGoalkeeper { return !$0.isGoalkeeper }
            return $0.number < $1.number
        }
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(players, id: \.number) { player in
                Button {
                    onSelect(player.number)
                } label: {
                    // A FILL, not a border: the heavy accent border is already
                    // how a goalkeeper tile is marked, so a selected shooter
                    // drawn with one looked like a third goalkeeper. The fill
                    // is brand amber, not blue, so it never reads as a
                    // heatmap rate.
                    PlayerTileView(player: player, isSelected: selectedNumber == player.number)
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

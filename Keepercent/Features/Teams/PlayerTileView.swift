// PlayerTileView and AddPlayerTileView draw one grid tile each for
// RosterGridView. PRESENTATIONAL per CLAUDE.md's container/presentational
// rule: they draw only the `KeepercentDomain.Player` value (or nothing at
// all, for the "+" tile) they are given, with no SwiftData import.
//
// Goalkeepers must be visually distinct WITHOUT relying on colour alone
// (T3.1 instruction: colour-only fails a colourblind scout and washes out
// in bright gym light). This view uses two additional channels together —
// a heavier, accent-tinted border, and a glove glyph badge — so the
// distinction survives even if colour perception or lighting removes one
// of them. All colours are semantic system colours (`Color.accentColor`,
// `Color(.secondarySystemBackground)`, `.primary`/`.secondary`), never a
// hardcoded light-mode grey, so the grid reads correctly in dark mode too.
//
// T2.1's lesson (see CourtView.swift's `drawZoneGrid` comment) was that a
// grid drawn at the same weight as its own decoration made the actual
// affordance invisible until someone ran the app. Applied here: the tile
// itself is a filled, bordered shape from the start, not a bare number on
// a blank background, so it reads as tappable at a glance.

import SwiftUI
import KeepercentDomain

/// The minimum both dimensions of any tappable tile in this grid, per
/// Apple's Human Interface Guidelines and this task's explicit 44x44
/// instruction. `PlayerTileView` and `AddPlayerTileView` both apply it via
/// `.frame(minWidth:minHeight:)`, so neither can shrink below it even on
/// the narrowest iPhone grid column.
let rosterTileMinimumDimension: CGFloat = 44

struct PlayerTileView: View {
    let player: Player

    private var accessibilityDescription: String {
        var parts = ["Number \(player.number)"]
        if let name = player.name, !name.isEmpty {
            parts.append(name)
        }
        if player.isGoalkeeper {
            parts.append("Goalkeeper")
        }
        return parts.joined(separator: ", ")
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                player.isGoalkeeper ? Color.accentColor : Color(.separator),
                                lineWidth: player.isGoalkeeper ? 3 : 1
                            )
                    }
                    .overlay {
                        Text("\(player.number)")
                            .font(.title2.bold().monospacedDigit())
                            .foregroundStyle(.primary)
                            .minimumScaleFactor(0.6)
                            .padding(4)
                    }
                    .frame(minWidth: rosterTileMinimumDimension, minHeight: rosterTileMinimumDimension)
                    .aspectRatio(1, contentMode: .fit)

                // Second channel (beyond the border) marking a goalkeeper:
                // a glove glyph badge, independent of the border colour so
                // the distinction survives even without colour vision.
                if player.isGoalkeeper {
                    Image(systemName: "hand.raised.fill")
                        .font(.caption2.bold())
                        .padding(4)
                        .background(Color.accentColor, in: Circle())
                        .foregroundStyle(Color(.systemBackground))
                        .offset(x: 6, y: -6)
                        .accessibilityHidden(true)
                }
            }

            Text(player.name ?? "Unnamed")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.isButton)
    }
}

/// The "+" tile that adds an unknown shirt number (docs/mvp.md §6). Kept
/// visually distinct from a player tile — dashed border, no number, a
/// muted fill — so it never reads as an eleventh roster entry.
struct AddPlayerTileView: View {
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.tertiarySystemFill))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(.systemGray3), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                }
                .overlay {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: rosterTileMinimumDimension, minHeight: rosterTileMinimumDimension)
                .aspectRatio(1, contentMode: .fit)

            Text("Unknown #")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Add player with unknown shirt number")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("Tiles") {
    HStack(spacing: 12) {
        PlayerTileView(player: Player(number: 7, name: "Ana", isGoalkeeper: false, handedness: .right))
        PlayerTileView(player: Player(number: 1, name: "Marta", isGoalkeeper: true, handedness: .left))
        PlayerTileView(player: Player(number: 23))
        AddPlayerTileView()
    }
    .padding()
}

#Preview("Tiles - Dark") {
    HStack(spacing: 12) {
        PlayerTileView(player: Player(number: 7, name: "Ana", isGoalkeeper: false, handedness: .right))
        PlayerTileView(player: Player(number: 1, name: "Marta", isGoalkeeper: true, handedness: .left))
        AddPlayerTileView()
    }
    .padding()
    .preferredColorScheme(.dark)
}

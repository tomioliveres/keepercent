// ShooterCardContentView is T4.3's PRESENTATIONAL card (CLAUDE.md
// container/presentational split): it only draws the `Player` and
// `StatsEngine` it is given — no SwiftData, no @Query, no ModelContext.
//
// Beyond T4.2's linked court<->goal view (reused here fixed to the
// `.effectiveness` reading, since a shooter card only ever asks "where do
// THEY score"), this card names where the shooter is dangerous with a
// ranking by goal COUNT, not by rate (`StatsEngine.topGoalZones`/
// `topOrigins`): a 1/1 zone never outranks a real 4/5 pattern just because
// its rate looks better — see odd/tasks/keepercent.md's T4.3 entry.
//
// docs/mvp.md §5.3 defines no minimum-sample rule, so — same as
// `HeatmapColor` and the header stats below — a shooter with zero
// recorded shots reads as "no shots yet", never as a 0% card.

import SwiftUI
import KeepercentDomain

struct ShooterCardContentView: View {
    let player: Player
    /// Already narrowed to this one shooter's own shots (T4.3's
    /// container does the narrowing via `StatsEngine.shots(by:)`, matching
    /// `TeamScoutingView`'s own container/presentational split).
    let engine: StatsEngine

    /// Local to this card, not shared with any other screen — same
    /// reasoning `TeamScoutingView` gives for its own `selection` @State:
    /// `LinkedZonesView` needs a `Binding`, and nothing outside this card
    /// cares which origin is currently selected.
    @State private var selection: ShotOrigin?

    private var fieldShots: StatsEngine { engine.fieldShots }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            LinkedZonesView(engine: engine, reading: .effectiveness, selection: $selection)
            whereTheyScoreSection
            shotShapeSection
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(playerTitle)
                .font(.title2.bold())
            Text(headerStatsLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var playerTitle: String {
        if let name = player.name, !name.isEmpty {
            return "#\(player.number) · \(name)"
        }
        return "#\(player.number)"
    }

    /// "12 shots · 5 goals · 42%", or "No shots recorded yet" when this
    /// shooter has nothing on record — never "0%", which would read as a
    /// measured weakness rather than an absence of data.
    private var headerStatsLine: String {
        let tally = engine.effectiveness
        guard tally.attempts > 0, let rate = tally.rate else { return "No shots recorded yet" }
        return "\(tally.attempts) shot\(tally.attempts == 1 ? "" : "s") · \(tally.successes) goal\(tally.successes == 1 ? "" : "s") · \(percentText(rate))"
    }

    // MARK: - Where they score

    private var whereTheyScoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Where they score").font(.headline)

            rankingColumn(title: "Goal zones", ranked: engine.topGoalZones(limit: 3)) { $0.displayName }
            rankingColumn(title: "Origins", ranked: engine.topOrigins(limit: 3)) { $0.displayName }
        }
    }

    /// One ranked list ("top left · 4/5"), or a "no goals yet" line when
    /// the ranking is empty — a shooter with only misses/saves recorded
    /// still has an effectiveness Tally, just nothing to rank here.
    private func rankingColumn<Key>(
        title: String,
        ranked: [RankedTally<Key>],
        name: @escaping (Key) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
            if ranked.isEmpty {
                Text("No goals recorded yet").foregroundStyle(.secondary)
            } else {
                ForEach(Array(ranked.enumerated()), id: \.offset) { _, entry in
                    HStack {
                        Text(name(entry.key))
                        Spacer()
                        // `HeatmapColor.label` already turns a `Tally` into
                        // exactly the "successes/attempts" text this
                        // ranking wants ("4/5") — reused rather than
                        // reformatted here.
                        if let label = HeatmapColor.label(for: entry.tally) {
                            Text(label).foregroundStyle(.secondary).monospacedDigit()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Shot shape

    /// The cross-shot vs near-post split and the dominant height, both
    /// read on `fieldShots` (7 m has no lateral side and would otherwise
    /// read as `.neutral`, muddying the split — same reasoning
    /// `LinkedZonesView`'s 7 m caption already documents).
    private var shotShapeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Shot shape").font(.headline)
            Text(lineSplitText)
            Text(dominantHeightText)
        }
        .foregroundStyle(.secondary)
    }

    private var lineSplitText: String {
        let lines = fieldShots.lineDistribution
        let crossShot = lines[.crossShot] ?? 0
        let nearPost = lines[.nearPost] ?? 0
        guard crossShot + nearPost > 0 else { return "No open-play shots yet" }
        return "Cross-shot \(crossShot) · Near-post \(nearPost)"
    }

    private var dominantHeightText: String {
        let heights = fieldShots.heightDistribution
        let most = heights.values.max() ?? 0
        guard most > 0 else { return "No dominant height yet" }
        // Walk the heights in their declared order so a tie is found the
        // same way every time; a tie has no dominant height to name.
        let leaders = ShotHeight.allCases.filter { heights[$0] == most }
        guard leaders.count == 1, let dominant = leaders.first else {
            return "No single dominant height"
        }
        return "Mostly \(dominant.rawValue) (\(most))"
    }

    // MARK: - Formatting

    private func percentText(_ rate: Double) -> String {
        rate.formatted(.percent.precision(.fractionLength(0)))
    }
}

#Preview("ShooterCardContentView") {
    ScrollView {
        ShooterCardContentView(
            player: DemoData.leftBackPauVidal,
            engine: StatsEngine(shots: DemoData.shots).shots(by: DemoData.leftBackPauVidal.number)
        )
        .padding()
    }
}

#Preview("ShooterCardContentView - no shots") {
    ScrollView {
        ShooterCardContentView(
            player: Player(number: 99, name: "Unscouted"),
            engine: StatsEngine(shots: [])
        )
        .padding()
    }
}

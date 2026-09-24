// GoalkeeperCardContentView is T4.4's PRESENTATIONAL card (CLAUDE.md
// container/presentational split): it only draws the `Player` and
// `StatsEngine` it is given — no SwiftData, no @Query, no ModelContext.
//
// Mirrors `ShooterCardContentView`'s own shape exactly, but reads the
// engine in the `.saveRate` sense (saves over shots on target) rather than
// `.effectiveness`: beyond T4.2's linked court<->goal view, this card names
// where the goalkeeper is weak and strong with two rankings by COUNT, not
// by rate (`StatsEngine.weakGoalZones`/`strongGoalZones`) — a 1/1 zone
// never outranks a real conceded/save pattern just because its rate looks
// better. See odd/tasks/keepercent.md's T4.4 entry.
//
// docs/mvp.md §5.3 defines no minimum-sample rule, so a goalkeeper with no
// shots faced reads as "no shots yet", never as a 0% card.

import SwiftUI
import KeepercentDomain

struct GoalkeeperCardContentView: View {
    let player: Player
    /// Already narrowed to the shots this one goalkeeper faced (T4.4's
    /// container does the narrowing via `StatsEngine.shots(facing:)`,
    /// matching `ShooterCardView`'s own container/presentational split).
    let engine: StatsEngine

    /// Local to this card, not shared with any other screen — same
    /// reasoning `ShooterCardContentView` gives for its own `selection`
    /// @State.
    @State private var selection: ShotOrigin?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            LinkedZonesView(engine: engine, reading: .saveRate, selection: $selection)
            weakZonesSection
            strongZonesSection
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

    /// "18 shots on target · 11 saves · 61%", or "No shots faced yet" when
    /// this goalkeeper has nothing on record — never "0%", which would
    /// read as a measured weakness rather than an absence of data.
    private var headerStatsLine: String {
        let tally = engine.saveRate
        guard tally.attempts > 0, let rate = tally.rate else { return "No shots faced yet" }
        return "\(tally.attempts) shot\(tally.attempts == 1 ? "" : "s") on target · \(tally.successes) save\(tally.successes == 1 ? "" : "s") · \(percentText(rate))"
    }

    // MARK: - Weak / strong zones

    // Both rankings read `fieldShots`, the same shots the goal heatmap shows
    // with nothing selected: 7 m stays apart (docs/mvp.md §6), so a penalty
    // conceded bottom left never inflates the zone the heatmap labels.
    private var weakZonesSection: some View {
        rankingSection(title: "Weak zones", ranked: engine.fieldShots.weakGoalZones(limit: 3), emptyText: "No goals conceded yet")
    }

    private var strongZonesSection: some View {
        rankingSection(title: "Strong zones", ranked: engine.fieldShots.strongGoalZones(limit: 3), emptyText: "No saves recorded yet")
    }

    /// One ranked list ("top left · 3/4"), or `emptyText` when the ranking
    /// is empty — matches `ShooterCardContentView.rankingColumn`'s own
    /// shape, one section per ranking instead of two side by side, since
    /// each of the goalkeeper's rankings gets its own headline here.
    private func rankingSection(
        title: String,
        ranked: [RankedTally<GoalZone>],
        emptyText: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            if ranked.isEmpty {
                Text(emptyText).foregroundStyle(.secondary)
            } else {
                ForEach(Array(ranked.enumerated()), id: \.offset) { _, entry in
                    HStack {
                        Text(entry.key.displayName)
                        Spacer()
                        // `HeatmapColor.label` already turns a `Tally` into
                        // exactly the "successes/attempts" text this
                        // ranking wants ("3/4") — reused rather than
                        // reformatted here, same as `ShooterCardContentView`.
                        if let label = HeatmapColor.label(for: entry.tally) {
                            Text(label).foregroundStyle(.secondary).monospacedDigit()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Formatting

    private func percentText(_ rate: Double) -> String {
        rate.formatted(.percent.precision(.fractionLength(0)))
    }
}

#Preview("GoalkeeperCardContentView") {
    ScrollView {
        GoalkeeperCardContentView(
            player: DemoData.goalkeeperMarcPuig,
            engine: StatsEngine(shots: DemoData.shots).shots(facing: DemoData.goalkeeperMarcPuig.number)
        )
        .padding()
    }
}

#Preview("GoalkeeperCardContentView - no shots") {
    ScrollView {
        GoalkeeperCardContentView(
            player: Player(number: 99, name: "Unscouted", isGoalkeeper: true),
            engine: StatsEngine(shots: [])
        )
        .padding()
    }
}

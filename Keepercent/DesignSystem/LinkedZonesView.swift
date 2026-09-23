// LinkedZonesView is T4.2's linked court<->goal component, reused by both
// the shooter card (T4.3) and the rival goalkeeper card (T4.4) through a
// `StatsReading` (CLAUDE.md container/presentational split: this view only
// draws a `StatsEngine` it is given, no SwiftData, no @Query).
//
// Tapping a court zone filters the goal side to that origin's shots
// (`StatsEngine.goalEngine(forSelectedOrigin:)`); tapping the same zone
// again clears the selection back to `fieldShots`. The 7 m mark is its own
// origin and always stays apart from field play, on both sides, per
// docs/mvp.md §6 — selecting it never falls back to `fieldShots`.
//
// The heatmap itself is painted straight into `CourtView`/`GoalView`'s own
// `Canvas` (their new `zoneTints`/`zoneLabels` params), never a second,
// independently-positioned overlay: the zone that is coloured is exactly
// the zone a tap resolves to (T2.1's rule). `HeatmapColor` turns a `Tally`
// into that colour and label; this view only decides WHICH tally goes
// where.

import SwiftUI
import Charts
import KeepercentDomain

struct LinkedZonesView: View {
    let engine: StatsEngine
    let reading: StatsReading
    @Binding var selection: ShotOrigin?

    /// Chooses the layout directly, rather than letting `ViewThatFits`
    /// guess from the space it is offered: inside an `HStack`, an iPhone
    /// portrait width is still enough for `ViewThatFits` to accept its
    /// side-by-side alternative, which then squeezes the court down to
    /// roughly 170 pt — no longer usable to tap a zone on. `.regular`
    /// (iPad, and an iPhone in landscape with Display Zoom off) reads as
    /// genuinely spacious; anything else stacks instead.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// The engine the goal side (tints AND chart) reads from: every field
    /// shot with nothing selected, or exactly the selected origin's shots
    /// otherwise. See `StatsEngine.goalEngine(forSelectedOrigin:)`'s own
    /// doc comment for why 7 m never falls back to `fieldShots`.
    private var goalEngine: StatsEngine {
        engine.goalEngine(forSelectedOrigin: selection)
    }

    var body: some View {
        if horizontalSizeClass == .regular {
            HStack(alignment: .top, spacing: 24) {
                courtColumn
                goalColumn
            }
        } else {
            // No side ever competes with the other for width here, so
            // each column's `CourtView`/`GoalView` is naturally proposed
            // the FULL available width — unlike inside the `HStack`
            // above, which is exactly the layout this branch exists to
            // avoid. The caller (`TeamScoutingView`) already scrolls its
            // whole screen, so this view does not nest a second
            // `ScrollView` of its own.
            VStack(alignment: .leading, spacing: 24) {
                courtColumn
                goalColumn
            }
        }
    }

    private var courtColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Origin").font(.headline)
            CourtView(
                selection: selection,
                zoneTints: tints(from: engine.originTallies(reading)),
                zoneLabels: labels(from: engine.originTallies(reading)),
                onOriginTapped: { origin, _ in
                    // Tapping the already-selected zone clears it: a
                    // second tap toggles back to "nothing selected"
                    // rather than requiring a separate clear control.
                    selection = (selection == origin) ? nil : origin
                }
            )
            // The 7 m mark still gets its tint on the court itself, but
            // never a label there: its rect sits on top of the
            // center-near zone's own rect, so the two labels used to
            // land on the same spot and read as one garbled tally.
            // Shown here instead, its own line, matching docs/mvp.md's
            // rule that 7 m is always shown apart from field play.
            Text(sevenMeterCaption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// "7 m: 1/2" when the 7 m mark has an on-target attempt recorded for
    /// the active `reading`, "7 m: no shots" otherwise — never a bare
    /// number that could be misread as a rate.
    private var sevenMeterCaption: String {
        let tally = engine.originTallies(reading)[.sevenMeters]
        guard let label = HeatmapColor.label(for: tally) else { return "7 m: no shots" }
        return "7 m: \(label)"
    }

    private var goalColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(reading == .effectiveness ? "Effectiveness" : "Save rate").font(.headline)
            GoalView(
                zoneTints: tints(from: goalEngine.goalZoneTallies(reading)),
                zoneLabels: labels(from: goalEngine.goalZoneTallies(reading)),
                onTargetTapped: { _ in }
            )
            captionView
            distributionCharts
        }
    }

    /// States the active filter and its sample size, so a caption alone —
    /// with no legend — tells a scout exactly what the goal side is
    /// showing right now.
    private var captionView: some View {
        Text("\(filterDescription) · \(goalEngine.shots.count) shot\(goalEngine.shots.count == 1 ? "" : "s")")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var filterDescription: String {
        guard let selection else { return "All field shots" }
        switch selection {
        case .sevenMeters:
            return "7 m throws"
        case .zone(let zone):
            return "From \(zone.sector.displayName) · \(zone.depth.displayName)"
        }
    }

    /// Two small bar charts over the active `goalEngine`, kept separate
    /// rather than one combined chart: height and outcome are different
    /// units (a target band vs. a result), and readable over clever wins
    /// here (this file's header comment).
    private var distributionCharts: some View {
        VStack(alignment: .leading, spacing: 16) {
            distributionChart(
                title: "Height",
                data: ShotHeight.allCases.map { ($0.rawValue, goalEngine.heightDistribution[$0] ?? 0) }
            )
            distributionChart(
                title: "Outcome",
                data: ShotOutcome.allCases.map { ($0.rawValue, goalEngine.outcomeCounts[$0] ?? 0) }
            )
        }
    }

    private func distributionChart(title: String, data: [(label: String, count: Int)]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Chart(data, id: \.label) { entry in
                BarMark(x: .value("Count", entry.count), y: .value("Label", entry.label))
            }
            .frame(height: CGFloat(data.count) * 24 + 16)
        }
    }

    // MARK: - Tally -> tint/label

    private func tints<Key: Hashable>(from tallies: [Key: Tally]) -> [Key: Color] {
        tallies.mapValues { HeatmapColor.tint(for: $0) }
    }

    private func labels<Key: Hashable>(from tallies: [Key: Tally]) -> [Key: String] {
        tallies.reduce(into: [Key: String]()) { result, entry in
            if let label = HeatmapColor.label(for: entry.value) {
                result[entry.key] = label
            }
        }
    }
}

private extension CourtSector {
    var displayName: String {
        switch self {
        case .leftWing: return "left wing"
        case .leftBack: return "left back"
        case .center: return "center"
        case .rightBack: return "right back"
        case .rightWing: return "right wing"
        }
    }
}

private extension CourtDepth {
    var displayName: String {
        switch self {
        case .near: return "near"
        case .far: return "far"
        }
    }
}

#Preview("LinkedZonesView") {
    ScrollView {
        LinkedZonesView(
            engine: StatsEngine(shots: DemoData.shots),
            reading: .effectiveness,
            selection: .constant(nil)
        )
        .padding()
    }
}

#Preview("LinkedZonesView - zone selected") {
    ScrollView {
        LinkedZonesView(
            engine: StatsEngine(shots: DemoData.shots),
            reading: .saveRate,
            selection: .constant(.zone(CourtZone(sector: .leftBack, depth: .near)))
        )
        .padding()
    }
}

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
//
// T6.8 adds two arrow modes over the same court: "Directions" (one arrow per
// origin towards its most frequent goal side, `StatsEngine.dominantDirections`)
// and "Every shot" (one thin arrow per shot, coloured by outcome). The mode
// lives in local `@State`: it is a per-screen viewing choice, never stored.
// Tapping still selects a zone exactly as in the heatmap mode.

import SwiftUI
import KeepercentDomain

struct LinkedZonesView: View {
    let engine: StatsEngine
    let reading: StatsReading
    @Binding var selection: ShotOrigin?
    @Environment(\.colorScheme) private var colorScheme
    @State private var courtMode: CourtMode = .zones

    /// What the court draws over its zones.
    enum CourtMode: CaseIterable, Identifiable {
        case zones
        case directions
        case everyShot

        var id: Self { self }

        var title: LocalizedStringKey {
            switch self {
            case .zones: "Zones"
            case .directions: "Directions"
            case .everyShot: "Every shot"
            }
        }
    }

    /// The engine the goal side (tints AND chart) reads from: every field
    /// shot with nothing selected, or exactly the selected origin's shots
    /// otherwise. See `StatsEngine.goalEngine(forSelectedOrigin:)`'s own
    /// doc comment for why 7 m never falls back to `fieldShots`.
    private var goalEngine: StatsEngine {
        engine.goalEngine(forSelectedOrigin: selection)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            goalColumn
            courtColumn
            captionView
            distributionCharts
        }
    }

    private var courtColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Origin").font(.headline)
            Picker("Court view", selection: $courtMode) {
                ForEach(CourtMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            CourtView(
                selection: selection,
                zoneTints: courtTints,
                zoneLabels: courtMode == .zones ? labels(from: engine.originTallies(reading)) : [:],
                arrows: arrows,
                accessibilityTallies: engine.originTallies(reading),
                accessibilityReading: reading,
                accessibilityNotes: courtMode == .zones ? [:] : directionNotes,
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
            arrowLegend
        }
    }

    /// Tint every selectable zone, including zones without recorded shots.
    /// CourtZone.allCases includes only three far zones: the far touchline
    /// strips share their side band's geometry, tally, and selection.
    /// Otherwise those areas show the court's green base and look like gaps
    /// even though CourtGeometry already accepts their taps as near zones.
    private var courtTints: [ShotOrigin: Color] {
        let tallies = engine.originTallies(reading)
        return Dictionary(uniqueKeysWithValues: CourtZone.allCases.map { zone in
            let origin = ShotOrigin.zone(zone)
            return (origin, HeatmapColor.tint(for: tallies[origin], appearance: colorScheme))
        } + [(.sevenMeters, HeatmapColor.tint(for: tallies[.sevenMeters], appearance: colorScheme))])
        .mapValues { courtMode == .zones ? $0 : $0.opacity(0.3) }
    }

    // MARK: - Arrows (T6.8)

    private var arrows: [CourtArrow] {
        switch courtMode {
        case .zones: return []
        case .directions: return directionArrows
        case .everyShot: return everyShotArrows
        }
    }

    /// With a zone selected, its arrows stay strong and every other one
    /// fades, so the arrow behind the filtered goal stands out.
    private func emphasis(for origin: ShotOrigin?) -> Double {
        guard let selection else { return 1 }
        return origin == selection ? 1 : 0.25
    }

    /// One arrow per origin towards its most frequent side: width grows
    /// with the shots to that side (2-10 pt), colour follows how they
    /// converted, and "4/6" sits by the tail.
    /// "4/6", or "7 m 1/2": the 7 m arrow starts right beside the
    /// center-near zone's arrow, so its label names itself.
    private func directionLabel(for direction: ShotDirection) -> String? {
        guard let label = HeatmapColor.label(for: direction.shots) else { return nil }
        return direction.origin == .sevenMeters ? "7 m \(label)" : label
    }

    private var directionArrows: [CourtArrow] {
        engine.dominantDirections(reading).map { direction in
            CourtArrow(
                tail: .origin(direction.origin),
                tip: CourtGeometry.standard.goalPoint(for: direction.side),
                width: min(10, max(2, 1.2 * CGFloat(direction.shots.successes))),
                color: HeatmapColor.arrowColor(for: direction.conversion).opacity(emphasis(for: direction.origin)),
                label: directionLabel(for: direction)
            )
        }
    }

    /// One thin arrow per shot, from its exact tap (or the 7 m mark) to
    /// the side it was aimed at, coloured by outcome. Low opacity lets
    /// overlapping arrows read as density.
    private var everyShotArrows: [CourtArrow] {
        engine.shots.compactMap { shot in
            let tail: CourtArrow.Tail
            if shot.isSevenMeters {
                tail = .origin(.sevenMeters)
            } else if let point = shot.originPoint {
                tail = .point(point)
            } else {
                return nil
            }
            return CourtArrow(
                tail: tail,
                tip: CourtGeometry.standard.goalPoint(for: ShotClassification.targetSide(shot.target)),
                width: 1.5,
                color: outcomeColor(shot.outcome).opacity(0.55 * emphasis(for: shot.origin)),
                label: nil
            )
        }
    }

    private func outcomeColor(_ outcome: ShotOutcome) -> Color {
        switch outcome {
        case .goal: return Palette.goal
        case .saved: return Palette.saved
        case .post: return Palette.post
        case .out: return Palette.miss
        }
    }

    /// What VoiceOver hears on each zone in the arrow modes, the same
    /// facts the direction arrow draws: "Most shots aimed right: 4 of 6,
    /// 3 goals".
    private var directionNotes: [ShotOrigin: String] {
        Dictionary(uniqueKeysWithValues: engine.dominantDirections(reading).map { direction in
            let share = share(of: direction)
            let conversion = direction.conversion
            switch reading {
            case .effectiveness:
                return (direction.origin, String(localized: "\(share), \(conversion.successes) goals"))
            case .saveRate:
                return (direction.origin, String(localized: "\(share), \(conversion.successes) saves of \(conversion.attempts) on target"))
            }
        })
    }

    /// "Most shots aimed right: 4 of 6" — one sentence per side, so each
    /// language words the side its own way.
    private func share(of direction: ShotDirection) -> String {
        let shots = direction.shots
        switch direction.side {
        case .left: return String(localized: "Most shots aimed left: \(shots.successes) of \(shots.attempts)")
        case .center: return String(localized: "Most shots aimed center: \(shots.successes) of \(shots.attempts)")
        case .right: return String(localized: "Most shots aimed right: \(shots.successes) of \(shots.attempts)")
        }
    }

    @ViewBuilder
    private var arrowLegend: some View {
        switch courtMode {
        case .zones:
            EmptyView()
        case .directions:
            VStack(alignment: .leading, spacing: 4) {
                if reading == .effectiveness {
                    Text("Width: shots · Color: goal rate")
                } else {
                    Text("Width: shots · Color: save rate")
                }
                HStack(spacing: 12) {
                    ForEach(Array(HeatmapColor.arrowSteps.enumerated()), id: \.offset) { index, color in
                        swatch(arrowStepNames[index], color: color)
                    }
                    swatch("No rate", color: HeatmapColor.arrowNoRate)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        case .everyShot:
            HStack(spacing: 12) {
                swatch("Goal", color: Palette.goal)
                swatch("Saved", color: Palette.saved)
                swatch("Post", color: Palette.post)
                swatch("Out", color: Palette.miss)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    /// One name per `HeatmapColor.arrowSteps` colour, lowest rate first.
    private let arrowStepNames: [LocalizedStringKey] = ["Low", "Mid", "High"]

    private func swatch(_ name: LocalizedStringKey, color: Color) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 4)
                .accessibilityHidden(true)
            Text(name)
        }
    }

    /// "7 m: 1/2" when the 7 m mark has an on-target attempt recorded for
    /// the active `reading`, "7 m: no shots" otherwise — never a bare
    /// number that could be misread as a rate.
    private var sevenMeterCaption: String {
        let tally = engine.originTallies(reading)[.sevenMeters]
        guard let label = HeatmapColor.label(for: tally) else { return String(localized: "7 m: no shots") }
        return String(localized: "7 m: \(label)")
    }

    private var goalColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(reading == .effectiveness ? LocalizedStringKey("Effectiveness") : LocalizedStringKey("Save rate"))
                .font(.headline)
            GoalView(
                zoneTints: goalTints,
                zoneLabels: labels(from: goalEngine.goalZoneTallies(reading)),
                missLabels: missLabels,
                accessibilityTallies: goalEngine.goalZoneTallies(reading),
                accessibilityReading: reading,
                isAccessibleAction: false,
                onTargetTapped: { _ in }
            )
        }
    }

    /// How many of the active `goalEngine`'s shots missed into each out
    /// zone, drawn in that zone so the card says where misses went. Empty
    /// zones get no label, the same way untried goal cells stay blank.
    private var missLabels: [GoalTarget: String] {
        goalEngine.missCounts.filter { $0.value > 0 }.mapValues(String.init)
    }

    /// States the active filter and its sample size, so a caption alone —
    /// with no legend — tells a scout exactly what the goal side is
    /// showing right now.
    private var captionView: some View {
        Text("\(filterDescription) · \(goalEngine.shots.count) shots")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var filterDescription: String {
        guard let selection else { return String(localized: "All field shots") }
        switch selection {
        case .sevenMeters:
            return String(localized: "7 m throws")
        case .zone(let zone):
            return String(localized: "From \(zone.sector.displayName()) · \(zone.depth.displayName())")
        }
    }

    /// Where the active `goalEngine`'s shots went, as two charts built
    /// from the same component: by height band and by side of the goal,
    /// each row split into goal / saved / post (T6.5). Misses have no band
    /// or column (see `StatsEngine.outcomesByHeight`), so they get one
    /// "Out" line shared by both charts, above the colour legend.
    private var distributionCharts: some View {
        VStack(alignment: .leading, spacing: 16) {
            OutcomeBreakdownChart(
                title: "Height",
                rows: ShotHeight.allCases.map { height in
                    .init(name: height.displayName().localizedCapitalized, highlight: .height(height), breakdown: breakdown(goalEngine.outcomesByHeight[height]))
                },
                reading: reading
            )
            OutcomeBreakdownChart(
                title: "Side",
                rows: ShotSide.allCases.map { side in
                    .init(name: side.displayName().localizedCapitalized, highlight: .side(side), breakdown: breakdown(goalEngine.outcomesBySide[side]))
                },
                reading: reading
            )
            VStack(alignment: .leading, spacing: 8) {
                Text("Out (wide/over): \(goalEngine.outcomeCounts[.out] ?? 0)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                OutcomeLegend()
            }
        }
    }

    /// Both breakdown maps are zero-filled, so the fallback never shows;
    /// it only spares the view a force unwrap.
    private func breakdown(_ value: OutcomeBreakdown?) -> OutcomeBreakdown {
        value ?? OutcomeBreakdown(goals: 0, saved: 0, posts: 0)
    }

    // MARK: - Tally -> tint/label

    /// Cover all nine goal cells, not only cells with shots. The tally map
    /// omits empty zones, but the drawing must still mark them as no data.
    private var goalTints: [GoalZone: Color] {
        let tallies = goalEngine.goalZoneTallies(reading)
        return Dictionary(uniqueKeysWithValues: GoalZone.allCases.map { zone in
            (zone, HeatmapColor.tint(for: tallies[zone], appearance: colorScheme))
        })
    }

    private func labels<Key: Hashable>(from tallies: [Key: Tally]) -> [Key: String] {
        tallies.reduce(into: [Key: String]()) { result, entry in
            if let label = HeatmapColor.label(for: entry.value) {
                result[entry.key] = label
            }
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

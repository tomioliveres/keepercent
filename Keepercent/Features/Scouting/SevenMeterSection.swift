import SwiftUI
import KeepercentDomain

/// A penalty-only record, independent of the linked court's selected origin.
struct SevenMeterSection: View {
    let engine: StatsEngine
    let reading: StatsReading
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    var body: some View {
        let sample = engine.sevenMeterShots
        VStack(alignment: .leading, spacing: 8) {
            Text("7 m throws").font(.headline)
            if sample.shots.isEmpty {
                Text("7 m: no shots")
                    .foregroundStyle(.secondary)
            } else {
                let counts = sample.outcomeCounts
                Text("Attempts: \(sample.shots.count) · Goals: \(counts[.goal] ?? 0) · Saves: \(counts[.saved] ?? 0) · Posts: \(counts[.post] ?? 0) · Out: \(counts[.out] ?? 0)")
                    .font(.subheadline)
                    .monospacedDigit()
                Text(summary(for: sample))
                    .font(.subheadline)
                    .monospacedDigit()
                goalHeatmap(for: sample)
                Text(reading == .effectiveness
                     ? LocalizedStringKey("Cells: goals / inside attempts · Outside: located misses")
                     : LocalizedStringKey("Cells: saves / on target inside · Outside: located misses"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func summary(for sample: StatsEngine) -> String {
        let tally = reading == .effectiveness ? sample.effectiveness : sample.saveRate
        guard let rate = tally.rate, let label = HeatmapColor.label(for: tally) else {
            return String(localized: "7 m throws: no shots on target recorded", locale: locale)
        }
        let percentage = rate.formatted(.percent.precision(.fractionLength(0)).locale(locale))
        switch reading {
        case .effectiveness:
            return String(localized: "Effectiveness: \(label) goals / attempts · \(percentage)", locale: locale)
        case .saveRate:
            return String(localized: "Save rate: \(label) saves / on target · \(percentage)", locale: locale)
        }
    }

    private func goalHeatmap(for sample: StatsEngine) -> some View {
        let tallies = sample.goalZoneTallies(reading)
        let tints = Dictionary(uniqueKeysWithValues: GoalZone.allCases.map { zone in
            (zone, HeatmapColor.tint(for: tallies[zone], appearance: colorScheme))
        })
        let labels = tallies.reduce(into: [GoalZone: String]()) { result, entry in
            if let label = HeatmapColor.label(for: entry.value) {
                result[entry.key] = label
            }
        }
        // Concrete misses alone have a location. Legacy misses remain in
        // the Out total above without being placed in an invented third.
        let misses = sample.missCounts.filter { $0.value > 0 }.mapValues(String.init)
        return GoalView(
            zoneTints: tints,
            zoneLabels: labels,
            missLabels: misses,
            accessibilityTallies: tallies,
            accessibilityReading: reading,
            isAccessibleAction: false,
            accessibilityScope: "goal.penalty",
            onTargetTapped: { _ in }
        )
    }
}

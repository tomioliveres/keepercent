// PatternsSection is a PRESENTATIONAL list of the strongest scouting
// patterns: it draws the `ScoutingPattern`s it is given, already found and
// ranked by `StatsEngine`, and phrases them with `PatternPhraser` — the same
// sentences the on-device model receives as facts.

import SwiftUI
import KeepercentDomain

struct PatternsSection: View {
    /// Already ranked, strongest first.
    let patterns: [ScoutingPattern]
    /// How many shots the patterns were read from, so an empty list can
    /// tell "too few shots" apart from "no clear tendency".
    let shotCount: Int

    /// Rows shown at most: enough to scout from, short enough to read.
    static let limit = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Patterns").font(.headline)
            if patterns.isEmpty {
                Text(emptyText).foregroundStyle(.secondary)
            } else {
                ForEach(Array(patterns.prefix(Self.limit).enumerated()), id: \.offset) { _, pattern in
                    row(pattern)
                }
            }
        }
    }

    private var emptyText: String {
        if shotCount < ScoutingPattern.minimumSample {
            return String(localized: "Not enough shots for patterns yet (at least \(ScoutingPattern.minimumSample) needed)")
        }
        return String(localized: "No clear pattern yet")
    }

    private func row(_ pattern: ScoutingPattern) -> some View {
        let sentence = PatternPhraser.sentence(for: pattern)
        return HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: symbol(for: pattern.kind))
                .foregroundStyle(Palette.accent)
                .frame(width: 24)
            Text(sentence)
            Spacer(minLength: 8)
            Text(figure(for: pattern))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        // The sentence already holds every number, so VoiceOver reads it
        // once instead of the icon, the sentence and the figure apart.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(sentence)
    }

    /// The sentence already says "6 of 7", so the trailing figure adds only
    /// the rate: "86 %", or "71 % vs 17 %" for a comparison.
    private func figure(for pattern: ScoutingPattern) -> String {
        let main = percentText(pattern.tally)
        guard let contrast = pattern.contrast else { return main }
        return String(localized: "\(main) vs \(percentText(contrast))")
    }

    private func percentText(_ tally: Tally) -> String {
        guard let rate = tally.rate else { return "–" }
        return rate.formatted(.percent.precision(.fractionLength(0)))
    }

    private func symbol(for kind: ScoutingPatternKind) -> String {
        switch kind {
        case .line, .lineFromSector: return "arrow.up.right"
        case .height, .concededHeight: return "arrow.up.and.down"
        case .side, .concededSide: return "arrow.left.and.right"
        case .deliveryHeight, .deliverySide, .approachSide, .deliverySaves: return "figure.handball"
        case .sevenMeterHeight, .sevenMeterSide, .sevenMeterSaves: return "7.circle"
        case .origin: return "mappin.and.ellipse"
        case .distance: return "ruler"
        case .repeatAfterGoal: return "repeat"
        }
    }
}

#Preview("PatternsSection") {
    PatternsSection(
        patterns: StatsEngine(shots: DemoData.shots).shots(by: DemoData.leftBackPauVidal.number).shooterPatterns(),
        shotCount: 10
    )
    .padding()
}

#Preview("PatternsSection - too few shots") {
    PatternsSection(patterns: [], shotCount: 2).padding()
}

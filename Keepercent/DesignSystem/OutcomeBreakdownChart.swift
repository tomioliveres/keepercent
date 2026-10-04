// OutcomeBreakdownChart (T6.5) draws one row per height band or goal side:
// a goal glyph, the row name, a bar split into goal / saved / post with the
// count inside each segment, and the row's figure for the active
// `StatsReading`. LinkedZonesView uses it twice ("Height" and "Side").
//
// Presentational only: it draws `OutcomeBreakdown`s it is given and computes
// no statistic itself — every number comes from `StatsEngine`.
//
// The bar is plain SwiftUI shapes rather than Swift Charts: three segments
// with a label inside are simpler to lay out by hand. Every bar is drawn on
// a faint track whose full width is ALL the chart's shots, so a bar reads as
// that row's share of the total — one shot out of one is a full bar because
// it really is all of them, not because it is the biggest row.

import SwiftUI
import KeepercentDomain

struct OutcomeBreakdownChart: View {
    struct Row: Identifiable {
        let name: String
        let highlight: GoalGlyph.Highlight
        let breakdown: OutcomeBreakdown

        var id: String { name }
    }

    let title: String
    let rows: [Row]
    let reading: StatsReading

    /// The shot count a full track stands for: every shot in the chart's
    /// rows. At least 1 so an empty chart never divides by zero.
    private var scale: Int {
        max(rows.map(\.breakdown.shots).reduce(0, +), 1)
    }

    /// What the right-hand figure counts, said once in the header instead of
    /// on every row, so the figure stays short enough for one line.
    private var figureCaption: String {
        reading == .saveRate ? "saves / on target" : "goals / shots"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.caption.weight(.semibold))
                Spacer()
                Text(figureCaption).font(.caption2)
            }
            .foregroundStyle(.secondary)
            ForEach(rows) { row in
                rowView(row)
            }
        }
    }

    private func rowView(_ row: Row) -> some View {
        HStack(spacing: 8) {
            GoalGlyph(highlight: row.highlight)
                .accessibilityHidden(true)
            Text(row.name.capitalized)
                .font(.caption)
                .frame(width: 52, alignment: .leading)
            bar(for: row.breakdown)
                .frame(height: 20)
            Text(figure(for: row.breakdown))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 96, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(for: row))
    }

    private func bar(for breakdown: OutcomeBreakdown) -> some View {
        GeometryReader { proxy in
            let unit = proxy.size.width / CGFloat(scale)
            HStack(spacing: 0) {
                segment(count: breakdown.goals, color: Palette.goal, width: unit)
                segment(count: breakdown.saved, color: Palette.saved, width: unit)
                segment(count: breakdown.posts, color: Palette.post, width: unit)
            }
            .frame(width: proxy.size.width, alignment: .leading)
            .background(Color(.tertiarySystemFill))
        }
    }

    /// One coloured block, `count` units wide, with its count printed inside
    /// when there is room for it. An empty segment draws nothing.
    @ViewBuilder
    private func segment(count: Int, color: Color, width unit: CGFloat) -> some View {
        if count > 0 {
            let width = unit * CGFloat(count)
            Rectangle()
                .fill(color)
                .frame(width: width)
                .overlay {
                    if width >= 16 {
                        Text("\(count)")
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.black)
                    }
                }
        }
    }

    /// "3/5 · 60%": goals over shots for the shooter, saves over shots on
    /// target for the goalkeeper (the header's `figureCaption` says which).
    /// A row with nothing to measure says so instead of showing 0%.
    private func figure(for breakdown: OutcomeBreakdown) -> String {
        let tally = breakdown.tally(reading)
        guard let rate = tally.rate else {
            return breakdown.shots == 0 ? "No shots" : "None on target"
        }
        return "\(tally.successes)/\(tally.attempts) · \(percent(rate))%"
    }

    /// "Top: 5 shots, 3 goals, 2 saved, 0 post. 3 of 5 goals, 60 percent".
    private func accessibilityLabel(for row: Row) -> String {
        let breakdown = row.breakdown
        let name = row.name.capitalized
        guard breakdown.shots > 0 else { return "\(name): no shots" }
        let counts = "\(name): \(breakdown.shots) shot\(breakdown.shots == 1 ? "" : "s"), "
            + "\(breakdown.goals) goal\(breakdown.goals == 1 ? "" : "s"), "
            + "\(breakdown.saved) saved, \(breakdown.posts) post"
        let tally = breakdown.tally(reading)
        guard let rate = tally.rate else { return "\(counts). None on target" }
        let noun = reading == .saveRate ? "saved" : "goals"
        return "\(counts). \(tally.successes) of \(tally.attempts) \(noun), \(percent(rate)) percent"
    }

    private func percent(_ rate: Double) -> Int {
        Int((rate * 100).rounded())
    }
}

/// The colour key shared by both outcome charts: a swatch plus a word, so
/// colour is never the only cue (segment counts carry the rest).
struct OutcomeLegend: View {
    var body: some View {
        HStack(spacing: 16) {
            entry("Goal", color: Palette.goal)
            entry("Saved", color: Palette.saved)
            entry("Post", color: Palette.post)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func entry(_ name: String, color: Color) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)
            Text(name)
        }
    }
}

#Preview("OutcomeBreakdownChart") {
    let engine = StatsEngine(shots: DemoData.shots).fieldShots
    VStack(alignment: .leading, spacing: 16) {
        OutcomeBreakdownChart(
            title: "Height",
            rows: ShotHeight.allCases.map {
                .init(name: $0.rawValue, highlight: .height($0), breakdown: engine.outcomesByHeight[$0] ?? OutcomeBreakdown(goals: 0, saved: 0, posts: 0))
            },
            reading: .effectiveness
        )
        OutcomeLegend()
    }
    .padding()
}

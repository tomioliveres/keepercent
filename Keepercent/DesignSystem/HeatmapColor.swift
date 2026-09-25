// HeatmapColor maps a `Tally` (KeepercentDomain) to a colour and an
// optional text label for `CourtView`/`GoalView`'s per-zone tints (T4.2).
// Kept separate from those views so the "what does this rate look like"
// decision stays a presentational concern, swappable without touching
// either view's drawing or hit-testing.

import SwiftUI
import KeepercentDomain

enum HeatmapColor {
    /// Opaque fills keep a recorded 0% visibly blue even on a dark canvas.
    /// Gray means no attempts; neither endpoint claims a minimum sample.
    /// These are temporary contrast colors, not T6.1a's brand assets.
    private static func noDataTint(for appearance: ColorScheme) -> Color {
        appearance == .dark
            ? Color(red: 0.26, green: 0.27, blue: 0.29)
            : Color(red: 0.88, green: 0.89, blue: 0.91)
    }

    /// Both ends stay legible under primary tally text in their appearance.
    private static func recordedTint(rate: Double, appearance: ColorScheme) -> Color {
        let low = appearance == .dark ? (0.20, 0.39, 0.59) : (0.72, 0.84, 0.95)
        let high = appearance == .dark ? (0.14, 0.35, 0.63) : (0.36, 0.59, 0.82)
        func blend(_ start: Double, _ end: Double) -> Double { start + rate * (end - start) }
        return Color(red: blend(low.0, high.0), green: blend(low.1, high.1), blue: blend(low.2, high.2))
    }

    /// A separate hue and a visible boundary distinguish selection from
    /// every blue rate and gray empty cell, including on the orange 7 m mark.
    static let selectionFill = Color(.systemPink).opacity(0.22)
    static let selectionOutline = Color(.systemPink)

    /// The tint for one zone's tally. Blue intensity scales with the
    /// rate in both appearances, so the map reads as one scale — a
    /// good/bad traffic light would itself be a "strong or weak"
    /// judgement, which is left to the card (T4.3/T4.4), not to this file.
    static func tint(for tally: Tally?, appearance: ColorScheme) -> Color {
        guard let tally, let rate = tally.rate else { return noDataTint(for: appearance) }
        return recordedTint(rate: rate, appearance: appearance)
    }

    /// A short "successes/attempts" label for the zone, or nil when there
    /// is nothing recorded to show. A tally with no attempts is "no data",
    /// as in `tint(for:)`, so it gets no label rather than "0/0".
    static func label(for tally: Tally?) -> String? {
        guard let tally, tally.attempts > 0 else { return nil }
        return "\(tally.successes)/\(tally.attempts)"
    }
}

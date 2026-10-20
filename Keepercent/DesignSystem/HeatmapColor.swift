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
    /// In dark mode empty cells are light gray, separating them from both
    /// rate endpoints by >=3:1. Text on these empty fills must be black.
    private static func noDataTint(for appearance: ColorScheme, contrast: ColorSchemeContrast) -> Color {
        appearance == .dark
            ? (contrast == .increased ? Color(white: 0.94) : Color(white: 0.84))
            : (contrast == .increased ? Color(white: 0.80) : Color(red: 0.88, green: 0.89, blue: 0.91))
    }

    /// Both ends stay legible under primary tally text in their appearance.
    /// Dark lightness rises with rate, with >=3:1 between endpoints while
    /// white labels retain >=4.5:1. Increased contrast widens the scale.
    private static func recordedTint(rate: Double, appearance: ColorScheme, contrast: ColorSchemeContrast) -> Color {
        let low: (Double, Double, Double)
        let high: (Double, Double, Double)
        if appearance == .dark {
            low = contrast == .increased ? (0.01, 0.06, 0.13) : (0.04, 0.16, 0.28)
            high = (0.10, 0.50, 0.62)
        } else {
            low = contrast == .increased ? (0.90, 0.95, 1.00) : (0.72, 0.84, 0.95)
            high = contrast == .increased ? (0.20, 0.48, 0.70) : (0.36, 0.59, 0.82)
        }
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
    static func tint(for tally: Tally?, appearance: ColorScheme, contrast: ColorSchemeContrast) -> Color {
        guard let tally, let rate = tally.rate else { return noDataTint(for: appearance, contrast: contrast) }
        return recordedTint(rate: rate, appearance: appearance, contrast: contrast)
    }

    /// The three steps of the arrow scale (T6.8), lowest first. A clear
    /// step scale reads better on a thin line than a smooth blend, and it
    /// stays one hue family (cyan to indigo) like the zone tints, so it
    /// never reads as a good/bad traffic light. System colours adapt to
    /// light and dark on their own.
    static let arrowSteps: [Color] = [Color(.systemCyan), Color(.systemBlue), Color(.systemIndigo)]

    /// An arrow whose conversion has no rate.
    static let arrowNoRate = Color(.systemGray)

    /// The colour of a shot-direction arrow for its conversion: gray when
    /// there is no rate (e.g. no shot on target for a goalkeeper),
    /// otherwise the third of `arrowSteps` the rate falls in.
    static func arrowColor(for tally: Tally) -> Color {
        guard let rate = tally.rate else { return arrowNoRate }
        let step = min(Int(rate * 3), arrowSteps.count - 1)
        return arrowSteps[step]
    }

    /// A short "successes/attempts" label for the zone, or nil when there
    /// is nothing recorded to show. A tally with no attempts is "no data",
    /// as in `tint(for:)`, so it gets no label rather than "0/0".
    static func label(for tally: Tally?) -> String? {
        guard let tally, tally.attempts > 0 else { return nil }
        return "\(tally.successes)/\(tally.attempts)"
    }
}

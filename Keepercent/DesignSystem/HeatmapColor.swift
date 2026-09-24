// HeatmapColor maps a `Tally` (KeepercentDomain) to a colour and an
// optional text label for `CourtView`/`GoalView`'s per-zone tints (T4.2).
// Kept separate from those views so the "what does this rate look like"
// decision stays a presentational concern, swappable without touching
// either view's drawing or hit-testing.

import SwiftUI
import KeepercentDomain

enum HeatmapColor {
    /// A `nil` tally — no dictionary entry, or one with a `nil` rate — reads
    /// as "no data": a flat, distinct gray that can never be mistaken for a
    /// 0% rate. docs/mvp.md §5.3 asks for no minimum-sample rule, so a zone
    /// nobody has shot at yet must never look like a weakness.
    static let noDataTint = Color(.systemGray4).opacity(0.5)

    /// The lowest and highest opacity a real rate can paint at. Neither end
    /// is 0 or 1: a 0% zone still needs to read as "recorded, and cold" —
    /// distinct from `noDataTint`'s flat gray — and a 100% zone should not
    /// fully hide the grid lines and any selection highlight drawn on top.
    private static let minOpacity = 0.15
    private static let maxOpacity = 0.85

    /// The tint for one zone's tally. Intensity (opacity) scales with the
    /// rate, all in a single hue, so darker always means "happens more
    /// often here" and the map reads as one continuous scale — a
    /// good/bad traffic light would itself be a "strong or weak"
    /// judgement, which is left to the card (T4.3/T4.4), not to this file.
    static func tint(for tally: Tally?) -> Color {
        guard let tally, let rate = tally.rate else { return noDataTint }
        return Color(.systemBlue).opacity(minOpacity + rate * (maxOpacity - minOpacity))
    }

    /// A short "successes/attempts" label for the zone, or nil when there
    /// is nothing recorded to show. A tally with no attempts is "no data",
    /// as in `tint(for:)`, so it gets no label rather than "0/0".
    static func label(for tally: Tally?) -> String? {
        guard let tally, tally.attempts > 0 else { return nil }
        return "\(tally.successes)/\(tally.attempts)"
    }
}

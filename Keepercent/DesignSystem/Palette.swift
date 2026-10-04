// Palette is the app's single list of named colours (T6.1a, "Amber arena").
// Brand colours come from the asset catalog, so each one carries its own
// light and dark value; data colours name a meaning ("a goal", "the 7 m
// mark") instead of a hue, so a feature never picks a raw system colour.
//
// The heatmap's blue scale and pink selection stay in `HeatmapColor`,
// which already owns that decision. Adaptive system tokens (`.primary`,
// `.secondary`, `Color(.systemBackground)`, `.separator`, GoalView's
// gray shades) are used directly: they are already semantic.

import SwiftUI

enum Palette {
    // MARK: - Brand

    /// The global tint (`AccentColor` asset): text buttons, links, chips,
    /// the goalkeeper border. Dark enough on light backgrounds and light
    /// enough on dark ones to be read as text.
    static let accent = Color.accentColor

    /// The bright amber fill for prominent actions and badges. Too light
    /// for white text, so anything drawn on it uses `onBrandAmber`.
    static let brandAmber = Color(.brandAmber)

    /// Dark navy for text and glyphs on `brandAmber`, in both appearances
    /// (the amber stays light in dark mode, so its text must stay dark).
    static let onBrandAmber = Color(.brandOnAmber)

    // MARK: - Shot outcomes

    /// The "Goal" answer when recording a shot.
    static let goal = Color.green

    /// The "Saved" answer when recording a shot.
    static let saved = Color.orange

    /// A shot that hit the frame: neutral gray, neither a goal nor a save.
    static let post = Color.gray

    /// A shot that missed the frame (T6.8 arrows): the adaptive primary
    /// colour, black in light mode and white in dark, so it stays neutral
    /// and still reads apart from the mid-gray `post`.
    static let miss = Color.primary

    // MARK: - Feedback

    /// Validation and error messages.
    static let error = Color.red

    /// Actions that remove data, such as undoing the last shot.
    static let destructive = Color.red

    // MARK: - Court

    /// The court surface: a faint green under every zone marking.
    static let courtSurface = Color(.systemGreen).opacity(0.12)

    /// The 7 m mark, kept orange so it stands apart from the court zones.
    static let sevenMeterMark = Color(.systemOrange).opacity(0.45)
}

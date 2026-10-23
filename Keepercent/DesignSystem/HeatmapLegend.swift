import SwiftUI
import KeepercentDomain

/// Rate endpoints and absence use the same palette as the cells, not a
/// separate gradient. Numeric cell samples remain the non-colour channel.
struct HeatmapLegend: View {
    var contrast: ColorSchemeContrast? = nil
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { entries }
            VStack(alignment: .leading, spacing: 8) { entries }
        }
        .font(.caption2)
    }

    @ViewBuilder private var entries: some View {
        entry("No data", tally: nil)
        entry("0%", tally: Tally(successes: 0, attempts: 1))
        entry("100%", tally: Tally(successes: 1, attempts: 1))
    }

    private func entry(_ title: LocalizedStringKey, tally: Tally?) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(HeatmapColor.tint(for: tally, appearance: colorScheme, contrast: contrast ?? colorSchemeContrast))
                .frame(width: 16, height: 12)
                .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(.secondary, lineWidth: 0.5))
                .accessibilityHidden(true)
            Text(title)
        }
        .fixedSize()
    }
}

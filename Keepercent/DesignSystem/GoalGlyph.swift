// GoalGlyph is a tiny goal outline (T6.5) that marks one height band or one
// side of the goal, so each row of an `OutcomeBreakdownChart` shows WHERE it
// is at a glance. Drawn from the shooter's point of view, like `GoalView`.
// Purely decorative: the row's own text and accessibility label carry the
// meaning, so callers hide it from VoiceOver.

import SwiftUI
import KeepercentDomain

struct GoalGlyph: View {
    /// The part of the goal to fill: a horizontal band or a vertical column.
    enum Highlight {
        case height(ShotHeight)
        case side(ShotSide)
    }

    let highlight: Highlight

    var body: some View {
        Canvas { context, size in
            let frame = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
            context.fill(Path(highlightRect(in: frame)), with: .color(Palette.brandAmber))
            context.stroke(Path(frame), with: .color(.primary), lineWidth: 1.5)
        }
        .frame(width: 30, height: 20)
    }

    /// One third of the frame: a row for a height band, a column for a side.
    private func highlightRect(in frame: CGRect) -> CGRect {
        switch highlight {
        case .height(let height):
            let third = frame.height / 3
            let index: CGFloat = switch height {
            case .top: 0
            case .middle: 1
            case .bottom: 2
            }
            return CGRect(x: frame.minX, y: frame.minY + third * index, width: frame.width, height: third)
        case .side(let side):
            let third = frame.width / 3
            let index: CGFloat = switch side {
            case .left: 0
            case .center: 1
            case .right: 2
            }
            return CGRect(x: frame.minX + third * index, y: frame.minY, width: third, height: frame.height)
        }
    }
}

#Preview("GoalGlyph") {
    HStack {
        GoalGlyph(highlight: .height(.top))
        GoalGlyph(highlight: .height(.bottom))
        GoalGlyph(highlight: .side(.left))
        GoalGlyph(highlight: .side(.center))
    }
    .padding()
}

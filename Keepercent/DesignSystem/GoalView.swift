// GoalView draws the handball goal (mouth, frame hit-band and out band) and
// converts a tap into a GoalTarget via GoalGeometry. It is a PRESENTATIONAL
// view per this project's container/presentational rule (CLAUDE.md): it only
// draws domain structs it receives and reports what happened through a
// closure. No SwiftData, no @Query, no ModelContext, no persistence import.
//
// Selection highlighting ("currently selected target") is explicitly NOT
// this view's job — that is T2.3. GoalView stays stateless.

import SwiftUI
import KeepercentDomain

struct GoalView: View {
    let geometry: GoalGeometry
    let onTargetTapped: (GoalTarget) -> Void

    init(geometry: GoalGeometry = .standard, onTargetTapped: @escaping (GoalTarget) -> Void) {
        self.geometry = geometry
        self.onTargetTapped = onTargetTapped
    }

    /// The visible margin drawn beyond the frame hit-band, where wideLeft /
    /// wideRight / over are tapped.
    ///
    /// This is a VIEW layout constant, not a `GoalGeometry` value, because
    /// the domain deliberately does not bound the miss area — `target(at:)`
    /// treats "everything beyond the frame band" as a miss, with no upper
    /// limit on how far out `x`/`y` can go (see `GoalPoint`'s header
    /// comment). The view still needs *some* finite margin to draw and to
    /// make tappable, so this constant lives here, sized to read clearly as
    /// "outside the goal" next to the mouth without pushing the frame band
    /// down to an illegibly thin sliver. 0.18 (18% of the mouth's own
    /// width/height) was chosen because it comfortably exceeds the frame
    /// band's own thickness (~8%, see `GoalGeometry.frameBandInMeters`), so
    /// the out band always reads as visually distinct from the frame band
    /// rather than nearly disappearing next to it.
    private let outBandFraction: Double = 0.18

    /// How much of the frame band's thickness the drawn goal line on the
    /// floor takes. The floor is not a frame member, so it must read as
    /// clearly lighter than a post while still closing the mouth.
    private let groundLineThicknessOfBand: Double = 0.3

    /// How many net cells span the mouth horizontally. The vertical count
    /// is derived from the goal's real proportions, so the net's cells stay
    /// square at any size and on any device, instead of stretching.
    ///
    /// A count, rather than a fixed point spacing: spacing in points would
    /// read as a coarse mesh on a phone and as fine gauze on an iPad. The
    /// net is purely decorative — it helps the mouth read as a goal at a
    /// glance and has no bearing on hit-testing, which only ever consults
    /// `GoalGeometry`.
    private let netCellsAcross = 12

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
        .aspectRatio(overallAspectRatio, contentMode: .fit)
        // The tap gesture is attached through an overlaid GeometryReader
        // rather than directly, because converting a tap into a GoalPoint
        // needs the drawn area's size and the gesture alone does not carry
        // it. The overlay sits on the ALREADY aspect-fitted view, so
        // `proxy.size` is exactly the size `Canvas` drew into, read
        // synchronously at tap time — no @State mirror of the layout, and
        // no first-tap race against onAppear.
        //
        // .onTapGesture over DragGesture(minimumDistance: 0): this view only
        // needs the tap's final location, not drag tracking or a pressed
        // state, and a plain tap gesture keeps GoalView's gesture handling
        // to the minimum it needs (see "stateless" note above).
        .overlay {
            GeometryReader { proxy in
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleTap(at: location, canvasSize: proxy.size)
                    }
            }
        }
        // Full per-zone VoiceOver support (announcing the specific zone/post
        // segment/miss direction under a tap) is T6.1; this is a minimal,
        // honest label so the control is not silently inaccessible today.
        .accessibilityLabel("Goal. Tap where the shot went.")
    }

    // MARK: - Layout

    /// The full drawn area's width, in the same normalized-mouth units as
    /// `GoalPoint`: 1 mouth-width plus a frame band and an out band on each
    /// side.
    private var overallWidth: Double {
        1 + 2 * (geometry.normalizedFrameBandThicknessX + outBandFraction)
    }

    /// The full drawn area's height: 1 mouth-height plus a frame band and an
    /// out band on top only (the ground line is the bottom edge — there is
    /// no "out band below the goal").
    private var overallHeight: Double {
        1 + geometry.normalizedFrameBandThicknessY + outBandFraction
    }

    /// The aspect ratio of the whole drawn area (mouth + bands), so the
    /// view keeps correct proportions at any size, from a narrow iPhone to
    /// a wide iPad.
    ///
    /// `overallWidth` and `overallHeight` are counted in MOUTH units, and
    /// those units are not square: one unit of `x` spans the whole 3 m
    /// mouth width, one unit of `y` the whole 2 m mouth height. Converting
    /// both back to metres before dividing is what makes the drawn mouth a
    /// real 3:2 goal instead of a square one.
    private var overallAspectRatio: Double {
        (overallWidth * geometry.widthInMeters) / (overallHeight * geometry.heightInMeters)
    }

    /// Converts a point in the mouth's normalized `0...1` frame into pixels
    /// within `size`, given how much extra space the frame/out bands take
    /// on each side. This is the single mapping both drawing and
    /// `mouthPoint(fromViewLocation:canvasSize:)` (hit-testing) share, so
    /// they cannot drift apart.
    private func pixelRect(for region: GoalRegion, in size: CGSize) -> CGRect {
        let layout = layout(in: size)

        return CGRect(
            x: layout.leftMargin + region.x * layout.scaleX,
            y: layout.topMargin + region.y * layout.scaleY,
            width: region.width * layout.scaleX,
            height: region.height * layout.scaleY
        )
    }

    /// How one mouth unit maps to pixels on each axis, and where the mouth's
    /// own origin sits inside the drawn area.
    ///
    /// The two scales are deliberately independent: a mouth unit of `x` is
    /// 3 m of real goal and a mouth unit of `y` is 2 m, so a single shared
    /// scale would draw a square mouth. With `overallAspectRatio` applied,
    /// `scaleX` and `scaleY` come out in the exact 3:2 relation that makes
    /// a metre horizontal and a metre vertical the same number of pixels.
    ///
    /// Both the forward mapping (`pixelRect`) and the inverse
    /// (`mouthPoint(fromViewLocation:canvasSize:)`) read this one function,
    /// so drawing and hit-testing cannot disagree about where anything is.
    private func layout(in size: CGSize) -> (scaleX: Double, scaleY: Double, leftMargin: Double, topMargin: Double) {
        let scaleX = size.width / overallWidth
        let scaleY = size.height / overallHeight

        return (
            scaleX: scaleX,
            scaleY: scaleY,
            leftMargin: (geometry.normalizedFrameBandThicknessX + outBandFraction) * scaleX,
            topMargin: (geometry.normalizedFrameBandThicknessY + outBandFraction) * scaleY
        )
    }

    // MARK: - Drawing

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let mouthRect = pixelRect(for: GoalRegion(x: 0, y: 0, width: 1, height: 1), in: size)

        drawOutBand(in: &context, size: size)
        drawMouth(in: &context, mouthRect: mouthRect, canvasSize: size)
        drawFrame(in: &context, size: size)
    }

    /// The out band: a visible margin beyond the frame band, distinct from
    /// both the mouth and the frame, because it is out of play.
    private func drawOutBand(in context: inout GraphicsContext, size: CGSize) {
        let fullRect = CGRect(origin: .zero, size: size)
        context.fill(Path(fullRect), with: .color(Color(.systemGray5)))
    }

    /// The mouth: the 3 m x 2 m goal opening, with a net texture and the 3x3
    /// grid taken from `geometry.region(for:)` — never divided by hand.
    private func drawMouth(in context: inout GraphicsContext, mouthRect: CGRect, canvasSize: CGSize) {
        context.fill(Path(mouthRect), with: .color(Color(.systemBackground)))
        drawNet(in: &context, mouthRect: mouthRect)
        drawGridLines(in: &context, canvasSize: canvasSize)
    }

    /// Decorative net texture: an evenly spaced grid of thin lines. Purely
    /// visual — spacing is a fixed point value (`netLineSpacing`), not
    /// derived from the domain, because the net has no bearing on
    /// hit-testing or zone boundaries.
    private func drawNet(in context: inout GraphicsContext, mouthRect: CGRect) {
        let columns = netCellsAcross
        let rows = Int((Double(netCellsAcross) * geometry.heightInMeters / geometry.widthInMeters).rounded())
        var netPath = Path()

        for column in 1..<columns {
            let x = mouthRect.minX + mouthRect.width * CGFloat(column) / CGFloat(columns)
            netPath.move(to: CGPoint(x: x, y: mouthRect.minY))
            netPath.addLine(to: CGPoint(x: x, y: mouthRect.maxY))
        }
        for row in 1..<rows {
            let y = mouthRect.minY + mouthRect.height * CGFloat(row) / CGFloat(rows)
            netPath.move(to: CGPoint(x: mouthRect.minX, y: y))
            netPath.addLine(to: CGPoint(x: mouthRect.maxX, y: y))
        }

        // Kept deliberately faint: the net is background texture, and the
        // 3x3 grid drawn over it is the affordance the user actually aims
        // at. If the two read at the same weight, the zones disappear.
        context.stroke(netPath, with: .color(.secondary.opacity(0.18)), lineWidth: 0.5)
    }

    /// The 3x3 inside-the-frame grid guides, one rect per `GoalZone`, each
    /// looked up via `geometry.region(for:)` so the boundaries can never
    /// drift from `target(at:)`'s own thirds.
    private func drawGridLines(in context: inout GraphicsContext, canvasSize: CGSize) {
        for zone in GoalZone.allCases {
            let rect = pixelRect(for: geometry.region(for: zone), in: canvasSize)
            // Dashed, and clearly heavier than the net: the nine zones are
            // what the user aims at during a match, so they have to be
            // readable at a glance and at arm's length. Dashes keep them
            // legible without competing with the solid frame.
            context.stroke(
                Path(rect),
                with: .color(.secondary.opacity(0.7)),
                style: StrokeStyle(lineWidth: 1, dash: [4, 3])
            )
        }
    }

    /// The frame: the posts and the crossbar, painted as EXACTLY the band
    /// that `GoalGeometry.target(at:)` resolves to a `.post(...)`.
    ///
    /// An earlier version drew a thin stroke centred on the mouth's edge
    /// and tinted a wider invisible hit band around it. That was wrong in
    /// two ways, both of which showed up the moment it was tapped. A stroke
    /// centred on the boundary puts half its own width INSIDE the mouth, so
    /// tapping what looked like the post recorded a shot inside the frame.
    /// And a painted stroke plus a tinted band plus the out band read as
    /// three different things, so nobody could tell where the post ended.
    ///
    /// The rule now is that what you see is what you tap: one post, one
    /// inside, one out. The drawn post is deliberately not to scale — a
    /// real post is about 8 cm against a 3 m mouth, which no finger could
    /// hit — but it is exactly the region that records a post.
    private func drawFrame(in context: inout GraphicsContext, size: CGSize) {
        let mouthRect = pixelRect(for: GoalRegion(x: 0, y: 0, width: 1, height: 1), in: size)
        let bandX = geometry.normalizedFrameBandThicknessX
        let bandY = geometry.normalizedFrameBandThicknessY
        let frameOuterRect = pixelRect(
            for: GoalRegion(x: -bandX, y: -bandY, width: 1 + 2 * bandX, height: 1 + bandY),
            in: size
        )

        var framePath = Path(frameOuterRect)
        framePath.addPath(Path(mouthRect))
        context.fill(framePath, with: .color(.primary), style: FillStyle(eoFill: true))

        drawFrameSegmentSeparators(in: &context, size: size)
        drawGroundLine(in: &context, mouthRect: mouthRect, size: size)
    }

    /// Faint separators between the nine frame segments, each traced from
    /// `geometry.region(for:)` so they land exactly where a tap changes
    /// which segment it records. Without them the frame is one solid mass
    /// and nothing suggests that a post has a top, a middle and a bottom.
    private func drawFrameSegmentSeparators(in context: inout GraphicsContext, size: CGSize) {
        for segment in PostSegment.allCases {
            let rect = pixelRect(for: geometry.region(for: segment), in: size)
            context.stroke(
                Path(rect),
                with: .color(Color(.systemBackground).opacity(0.45)),
                lineWidth: 0.5
            )
        }
    }

    /// The goal line on the floor. A real goal has no bottom member, so
    /// this is deliberately NOT painted as part of the frame: it is thinner
    /// and lighter, and it only closes the mouth so the posts do not read
    /// as cut off at the edge of the view. It also marks where
    /// `GoalGeometry` resolves a tap from below — the ball cannot pass
    /// under the floor.
    private func drawGroundLine(in context: inout GraphicsContext, mouthRect: CGRect, size: CGSize) {
        let bandPixels = geometry.normalizedFrameBandThicknessY * layout(in: size).scaleY
        let thickness = bandPixels * groundLineThicknessOfBand
        let groundY = mouthRect.maxY - thickness / 2

        var groundLine = Path()
        groundLine.move(to: CGPoint(x: mouthRect.minX, y: groundY))
        groundLine.addLine(to: CGPoint(x: mouthRect.maxX, y: groundY))
        context.stroke(groundLine, with: .color(.secondary), lineWidth: thickness)
    }

    // MARK: - Hit-testing

    /// The single place a tap's view-pixel location becomes a domain
    /// `GoalPoint`, in the mouth's normalized frame (0,0 = the mouth's
    /// top-left inside corner, 1,1 = its bottom-right). Every other
    /// GoalView function that needs this conversion goes through here.
    ///
    /// The direction matters: a tap in the left out band must resolve to a
    /// NEGATIVE `x` (not a clamped 0), because `GoalPoint` deliberately
    /// does not clamp — that is what makes `wideLeft` reachable at all (see
    /// `GoalPoint`'s header comment). This is a plain affine inverse of
    /// `pixelRect`'s forward mapping: subtract the margins, then divide by
    /// the same scale, with no min/max clamp anywhere in the expression.
    private func mouthPoint(fromViewLocation location: CGPoint, canvasSize: CGSize) -> GoalPoint {
        let layout = layout(in: canvasSize)
        guard layout.scaleX > 0, layout.scaleY > 0 else { return GoalPoint(x: 0.5, y: 0.5) }

        let x = (location.x - layout.leftMargin) / layout.scaleX
        let y = (location.y - layout.topMargin) / layout.scaleY
        return GoalPoint(x: x, y: y)
    }

    private func handleTap(at location: CGPoint, canvasSize: CGSize) {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return }
        let point = mouthPoint(fromViewLocation: location, canvasSize: canvasSize)
        let target = geometry.target(at: point)
        onTargetTapped(target)
    }
}

#Preview("GoalView") {
    GoalView { target in
        print("Tapped: \(target.code)")
    }
    .padding()
}

#Preview("GoalView - Dark") {
    GoalView { target in
        print("Tapped: \(target.code)")
    }
    .padding()
    .preferredColorScheme(.dark)
}

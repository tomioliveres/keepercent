// GoalView draws the handball goal (mouth, frame hit-band and out band) and
// converts a tap into a GoalTarget via GoalGeometry. It is a PRESENTATIONAL
// view per this project's container/presentational rule (CLAUDE.md): it only
// draws domain structs it receives and reports what happened through a
// closure. No SwiftData, no @Query, no ModelContext, no persistence import.
//
// Selection highlighting ("currently selected target") is drawn from the
// `selection` property (T2.3), passed IN by the caller rather than held in
// local `@State`. This is deliberate, not an oversight: an internal
// `@State` would make it impossible for a caller (T4.2's linked court-goal
// view) to highlight a target that was never tapped in THIS view. GoalView
// still has no `@State` of its own and stays a plain, side-effect-free
// `struct` — only WHERE the selection lives changed, not the
// container/presentational split.

import SwiftUI
import KeepercentDomain

struct GoalView: View {
    let geometry: GoalGeometry
    /// The target this view should currently highlight, passed in by the
    /// caller — see this file's header comment for why it is not local
    /// `@State`. `nil` draws no highlight.
    let selection: GoalTarget?
    /// A heatmap tint per goal zone (T4.2's linked view). Empty by default,
    /// which keeps ordinary shot entry byte-for-byte unchanged — this
    /// param only exists so the linked view can paint `StatsEngine`'s
    /// tallies straight onto the same `Canvas` a tap already resolves
    /// against, instead of a second, independently-positioned overlay
    /// that could drift from `geometry.region(for:)`. Resolved `Color`s,
    /// not raw tallies: the mapping from a `Tally` to a shade is a
    /// presentational decision (`HeatmapColor`) this view has no opinion
    /// on, so it stays dumb and only paints what it is given.
    let zoneTints: [GoalZone: Color]
    /// An optional short label per zone ("3/5"), drawn centred in the
    /// zone once its tint is painted. Empty by default; skipped when
    /// `zoneTints` has nothing for that zone either, so a caller that
    /// only wants colour and no digits can leave this empty.
    let zoneLabels: [GoalZone: String]
    let onTargetTapped: (GoalTarget) -> Void

    init(
        geometry: GoalGeometry = .standard,
        selection: GoalTarget? = nil,
        zoneTints: [GoalZone: Color] = [:],
        zoneLabels: [GoalZone: String] = [:],
        onTargetTapped: @escaping (GoalTarget) -> Void
    ) {
        self.geometry = geometry
        self.selection = selection
        self.zoneTints = zoneTints
        self.zoneLabels = zoneLabels
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

    /// Shared "this is the current selection" tint with `CourtView`'s own
    /// identical constant. No shared palette file exists (CLAUDE.md), so
    /// this literal is kept in sync with `CourtView.swift` by convention,
    /// not by import. Blue reads as selection across iOS and does not
    /// collide with any other semantic color already used in this file
    /// (the out band's grays, the frame's `.primary`). 0.45 matches the
    /// opacity `CourtView.drawSevenMeterMark` already uses for its own
    /// translucent fill over line art, a value already proven not to
    /// swallow the dashed zone grid underneath it.
    private let selectionHighlightColor = Color(.systemBlue).opacity(0.45)

    /// The tint for each `MissDirection`'s share of the out band.
    ///
    /// `regions(for:within:)` tiles the WHOLE band, so leaving all three
    /// on one shade would repaint a single flat field and hide the split
    /// this task exists to make visible. But three DIFFERENT shades lie
    /// the other way: `wideLeft` and `wideRight` are the same miss
    /// mirrored, and giving them different weights implies a difference
    /// that does not exist. They also never touch — the whole goal sits
    /// between them — so position alone already tells them apart, with no
    /// help from colour.
    ///
    /// So colour carries the one distinction position cannot: wide (the
    /// miss a keeper dives for) against high (the one that goes over).
    /// The two wide areas share a shade, `.over` takes the other, and the
    /// only two areas that actually share an edge — a wide one and
    /// `.over`, at each top corner — are the two that differ.
    private func outBandTint(for direction: MissDirection) -> Color {
        switch direction {
        case .wideLeft, .wideRight: return Color(.systemGray4)
        case .over: return Color(.systemGray2)
        }
    }

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
    ///
    /// Internal rather than private so a container laying the goal out next
    /// to another view (the entry screen's middle column) reads the ratio the
    /// goal actually draws with, instead of a copied literal that drifts.
    var overallAspectRatio: Double {
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

    /// The view's own drawn canvas — pixel `(0, 0)` to `(size.width,
    /// size.height)` — expressed as a `GoalRegion` in the same normalized
    /// mouth frame `GoalGeometry.regions(for:within:)` reads from. This is
    /// the exact inverse of `pixelRect`'s forward mapping (through
    /// `layout(in:)`, the one shared conversion this file already commits
    /// to — see `mouthPoint(fromViewLocation:canvasSize:)`'s own header
    /// comment), so it is not a second, independently-derived coordinate
    /// conversion: it is `layout(in:)` read backwards.
    ///
    /// `drawOutBand` passes this as `bounds` so the tiled miss regions it
    /// draws reach exactly as far as the canvas itself does — no further
    /// (a wasted rect nothing on screen shows) and no less (the gap this
    /// task's defect was about).
    private func normalizedBounds(for size: CGSize) -> GoalRegion {
        let layout = layout(in: size)
        guard layout.scaleX > 0, layout.scaleY > 0 else {
            return GoalRegion(x: 0, y: 0, width: 0, height: 0)
        }
        let minX = -layout.leftMargin / layout.scaleX
        let minY = -layout.topMargin / layout.scaleY
        let maxX = (Double(size.width) - layout.leftMargin) / layout.scaleX
        let maxY = (Double(size.height) - layout.topMargin) / layout.scaleY
        return GoalRegion(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    // MARK: - Drawing

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let mouthRect = pixelRect(for: GoalRegion(x: 0, y: 0, width: 1, height: 1), in: size)

        drawOutBand(in: &context, size: size)
        drawMouth(in: &context, mouthRect: mouthRect, canvasSize: size)
        drawFrame(in: &context, size: size)
        drawSelectionHighlight(in: &context, size: size)
    }

    /// The out band: a visible margin beyond the frame band, distinct from
    /// both the mouth and the frame, because it is out of play.
    ///
    /// Split into three tinted areas, one per `MissDirection` (T2.3) — a
    /// selected miss needs somewhere to visibly land, and a single flat
    /// fill gave it nowhere.
    ///
    /// An earlier version tinted only `geometry.region(for: direction)`
    /// verbatim — a single rect that was, by that function's own
    /// documented contract, a finite SUBSET of the true, unbounded miss
    /// area (see `GoalPoint`'s header comment: `target(at:)` never
    /// clamps). That was the same "what you see is what you tap" defect
    /// `drawFrame`'s header comment documents fixing once already, just
    /// for the out band instead of the frame: most of the drawn margin sat
    /// past that small rect, reading as undifferentiated gray while still
    /// hit-testing as that same miss direction. `regions(for:within:)`
    /// replaces it with the exact tiling of `bounds` — this view's own
    /// canvas, via `normalizedBounds(for:)` — so every pixel that
    /// `target(at:)` would resolve to a given `MissDirection` carries that
    /// direction's own tint, all the way to the canvas edge.
    ///
    /// The base `.systemGray5` fill underneath still matters: it is the
    /// fallback for whatever `bounds` does NOT reach (a degenerate/tiny
    /// canvas can make `regions(for:within:)` return fewer rects, or none
    /// — see that function's doc comment), so no pixel is ever left
    /// undrawn.
    private func drawOutBand(in context: inout GraphicsContext, size: CGSize) {
        let fullRect = CGRect(origin: .zero, size: size)
        context.fill(Path(fullRect), with: .color(Color(.systemGray5)))

        let bounds = normalizedBounds(for: size)
        for direction in MissDirection.allCases {
            for region in geometry.regions(for: direction, within: bounds) {
                let rect = pixelRect(for: region, in: size)
                context.fill(Path(rect), with: .color(outBandTint(for: direction)))
            }
        }
    }

    /// The mouth: the 3 m x 2 m goal opening, with a net texture and the 3x3
    /// grid taken from `geometry.region(for:)` — never divided by hand.
    private func drawMouth(in context: inout GraphicsContext, mouthRect: CGRect, canvasSize: CGSize) {
        context.fill(Path(mouthRect), with: .color(Color(.systemBackground)))
        drawNet(in: &context, mouthRect: mouthRect)
        drawZoneTints(in: &context, canvasSize: canvasSize)
        drawGridLines(in: &context, canvasSize: canvasSize)
        drawZoneLabels(in: &context, canvasSize: canvasSize)
    }

    /// The heatmap tint per zone (T4.2), painted on the exact same rect
    /// `drawGridLines` outlines — `geometry.region(for:)`, never a second,
    /// independently-derived rect — so the coloured zone and the zone a
    /// tap resolves to are always the same one. Drawn after the net but
    /// before the grid lines and the selection highlight, so the dashed
    /// guides and a live selection both stay legible on top of it.
    private func drawZoneTints(in context: inout GraphicsContext, canvasSize: CGSize) {
        for (zone, tint) in zoneTints {
            let rect = pixelRect(for: geometry.region(for: zone), in: canvasSize)
            context.fill(Path(rect), with: .color(tint))
        }
    }

    /// The optional "successes/attempts" label for each tinted zone,
    /// centred in the same rect the tint and the grid line share.
    private func drawZoneLabels(in context: inout GraphicsContext, canvasSize: CGSize) {
        for (zone, label) in zoneLabels {
            let rect = pixelRect(for: geometry.region(for: zone), in: canvasSize)
            let text = Text(label).font(.caption2.weight(.semibold)).foregroundStyle(.primary)
            context.draw(context.resolve(text), at: CGPoint(x: rect.midX, y: rect.midY))
        }
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

    /// Fills the region(s) the currently `selection`ed target corresponds
    /// to. Drawn last, on top of the mouth grid, the frame and the
    /// out-band accents, so the highlight stays visible no matter which of
    /// the three `GoalTarget` cases is selected. `geometry.regions(for:
    /// within:)` is the one call that already covers all three (`.inside`,
    /// `.post`, `.out`), so this needs no `switch` of its own.
    ///
    /// A selected `.out` target can return more than one rect — the same
    /// `bounds`-clipped tiling `drawOutBand` fills — so every rect that
    /// resolves to that `MissDirection` gets highlighted, not just
    /// whichever one happens to sit nearest the frame. That keeps the
    /// highlight consistent with the same "what you see is what you tap"
    /// rule the rest of this file follows: the WHOLE area a tap there
    /// would record is the area that lights up.
    private func drawSelectionHighlight(in context: inout GraphicsContext, size: CGSize) {
        guard let selection else { return }
        let bounds = normalizedBounds(for: size)
        for region in geometry.regions(for: selection, within: bounds) {
            let rect = pixelRect(for: region, in: size)
            context.fill(Path(rect), with: .color(selectionHighlightColor))
        }
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

#Preview("GoalView - Selected") {
    GoalView(selection: .out(.wideLeft)) { target in
        print("Tapped: \(target.code)")
    }
    .padding()
}

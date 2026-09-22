// CourtView draws the handball half-court (surface, goal mouth, 6 m/9 m
// lines, sector cuts and the 7 m mark) and converts a tap into a
// ShotOrigin via CourtGeometry. It is a PRESENTATIONAL view per this
// project's container/presentational rule (CLAUDE.md): it only draws
// domain structs it receives and reports what happened through a closure.
// No SwiftData, no @Query, no ModelContext, no persistence import.
//
// Selection highlighting ("currently selected origin") is drawn from the
// `selection` property (T2.3), passed IN by the caller rather than held in
// local `@State` — same reasoning as `GoalView`'s own header comment: an
// internal `@State` would make it impossible for a caller (T4.2's linked
// court-goal view) to highlight an origin that was never tapped in THIS
// view. CourtView still has no `@State` of its own.
//
// Layout is simpler than GoalView's. The goal needed two INDEPENDENT axis
// scales because its normalized box mixed an out band with two different
// metre spans per axis (a 3 m wide, 2 m tall mouth). Here a normalized
// CourtPoint already maps directly onto the drawn court rectangle:
// `geometry.aspectRatio` (width / depth) is exactly the ratio
// `.aspectRatio(_:contentMode:.fit)` draws the view at, so a normalized
// x-unit (spanning the whole court WIDTH) and a normalized y-unit
// (spanning the whole court DEPTH) come out to the same number of pixels
// once the view has that shape:
//   pixels-per-metre-x = size.width / widthInMeters
//   pixels-per-metre-y = size.height / depthInMeters
// and size.width / size.height == widthInMeters / depthInMeters by
// construction, so those two are always equal. One shared scale, not two
// — see `pixelPoint(for:in:)`, the single conversion both drawing and
// hit-testing call.
//
// Orientation: y = 0 (the goal line) is the TOP of the view, y = 1 (the
// far edge) is the bottom. x = 0 (the shooter's left touchline) is screen
// left. This is the shooter's own point of view, per CourtGeometry's and
// CourtZone's header comments.

import SwiftUI
import KeepercentDomain

struct CourtView: View {
    let geometry: CourtGeometry
    /// The origin this view should currently highlight, passed in by the
    /// caller — see this file's header comment for why it is not local
    /// `@State`. `nil` draws no highlight.
    let selection: ShotOrigin?
    let onOriginTapped: (ShotOrigin) -> Void

    /// Shared "this is the current selection" tint with `GoalView`'s own
    /// identical constant. No shared palette file exists (CLAUDE.md), so
    /// this literal is kept in sync with `GoalView.swift` by convention,
    /// not by import. Blue reads as selection across iOS and does not
    /// collide with this file's own surface green or 7 m mark orange.
    /// 0.45 matches `drawSevenMeterMark`'s own opacity, already proven not
    /// to swallow the dashed zone grid or the 9 m line underneath it.
    private let selectionHighlightColor = Color(.systemBlue).opacity(0.45)

    init(
        geometry: CourtGeometry = .standard,
        selection: ShotOrigin? = nil,
        onOriginTapped: @escaping (ShotOrigin) -> Void
    ) {
        self.geometry = geometry
        self.selection = selection
        self.onOriginTapped = onOriginTapped
    }

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
        .aspectRatio(geometry.aspectRatio, contentMode: .fit)
        // Same approach as GoalView: an overlaid GeometryReader on the
        // ALREADY aspect-fitted view, so `proxy.size` is exactly what
        // `Canvas` drew into, read synchronously at tap time. See
        // GoalView's own comment on this for the full reasoning (no
        // @State layout mirror, no first-tap race, plain tap over drag).
        .overlay {
            GeometryReader { proxy in
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleTap(at: location, canvasSize: proxy.size)
                    }
            }
        }
        // Full per-zone VoiceOver support (announcing the specific sector,
        // depth band or the 7 m mark under a tap) is T6.1; this is a
        // minimal, honest label so the control is not silently
        // inaccessible today — same level of detail as GoalView's.
        .accessibilityLabel("Half-court. Tap where the shot was taken from.")
    }

    // MARK: - Layout

    /// Converts a normalized `CourtPoint` into pixels within `size`. This
    /// is the ONE mapping both drawing and `courtPoint(fromViewLocation:
    /// canvasSize:)` (hit-testing) share, so they cannot drift apart — the
    /// same single-source-of-truth contract `GoalView.layout(in:)` gives
    /// the goal, just simpler here because only one scale is needed (see
    /// this file's header for why).
    private func pixelPoint(for point: CourtPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }

    /// The same conversion for a `CourtRegion` — used only for the 7 m
    /// mark's tap/hit area, so the drawn fill and `origin(at:)`'s
    /// classification can never disagree about where it sits.
    private func pixelRect(for region: CourtRegion, in size: CGSize) -> CGRect {
        CGRect(
            x: region.x * size.width,
            y: region.y * size.height,
            width: region.width * size.width,
            height: region.height * size.height
        )
    }

    /// A polyline through normalized points, for the curved 6 m/9 m lines.
    private func path(for points: [CourtPoint], in size: CGSize) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: pixelPoint(for: first, in: size))
        for point in points.dropFirst() {
            path.addLine(to: pixelPoint(for: point, in: size))
        }
        return path
    }

    /// A single straight segment, for the goal mouth and the sector rays.
    private func path(for segment: CourtSegment, in size: CGSize) -> Path {
        path(for: [segment.from, segment.to], in: size)
    }

    // MARK: - Drawing

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        drawSurface(in: &context, size: size)
        drawSixMeterLine(in: &context, size: size)
        drawZoneGrid(in: &context, size: size)
        drawSevenMeterMark(in: &context, size: size)
        drawSelectionHighlight(in: &context, size: size)
        drawOutline(in: &context, size: size)
        drawGoalMouth(in: &context, size: size)
    }

    /// The court surface. Filled first so every other element draws on
    /// top of it.
    private func drawSurface(in context: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        context.fill(Path(rect), with: .color(Color(.systemGreen).opacity(0.12)))
    }

    /// The court's boundary — touchlines, far edge and goal line — as the
    /// plain outline of the drawn rectangle. Drawn over the zone markings
    /// so the physical boundary reads as a crisp edge instead of getting
    /// buried under them.
    ///
    /// Inset by half the line width: a stroke is centred on its path, so
    /// an un-inset rect loses half of every edge off the side of the
    /// canvas and the court reads as thinner on its boundary than
    /// anywhere else.
    private func drawOutline(in context: inout GraphicsContext, size: CGSize) {
        let lineWidth: CGFloat = 2
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        context.stroke(Path(rect), with: .color(.primary), lineWidth: lineWidth)
    }

    /// The goal mouth, from `geometry.goalMouth`, drawn as a bold segment
    /// across the goal line so it reads as an actual goal rather than
    /// disappearing into the top edge of the outline rect. Drawn last,
    /// because at that one spot the goal matters more than the boundary
    /// running through it.
    ///
    /// The mouth sits at `y = 0`, the very top of the canvas, so the
    /// stroke is pushed down by half its width to stay inside it —
    /// otherwise half the bar is clipped away and the goal reads as
    /// floating above the court. The offset is applied HERE, in the
    /// drawing, and never in `pixelPoint(for:in:)`: that function is the
    /// exact inverse the hit-testing depends on, and nudging it would
    /// move every tap along with the ink.
    private func drawGoalMouth(in context: inout GraphicsContext, size: CGSize) {
        let lineWidth: CGFloat = 6
        let mouth = path(for: geometry.goalMouth, in: size)
            .offsetBy(dx: 0, dy: lineWidth / 2)
        context.stroke(mouth, with: .color(.primary), style: StrokeStyle(lineWidth: lineWidth, lineCap: .square))
    }

    /// The 6 m line. It plays no part in `origin(at:)`, so it stays
    /// secondary to the zone grid — but not faint: it is the line a
    /// handball player reads the whole court against, the edge of the
    /// goal area, and it is what tells a scout whether a shot came from
    /// the pivot or from a back. Solid and legible, against the grid's
    /// heavier dash, so the two never get confused for each other.
    private func drawSixMeterLine(in context: inout GraphicsContext, size: CGSize) {
        let line = path(for: geometry.line(atDistanceInMeters: geometry.sixMeterLine), in: size)
        context.stroke(line, with: .color(.secondary.opacity(0.55)), lineWidth: 1)
    }

    /// The zone grid: the 9 m line plus the four sector rays, together
    /// EXACTLY the boundaries `zone(at:)` classifies against. Drawn as one
    /// combined dashed stroke, clearly heavier than the 6 m line, so the
    /// ten zones read as the thing being tapped.
    ///
    /// This is the lesson T2.1 learned the hard way: `GoalView`'s first
    /// 3x3 grid was drawn at the same weight as its decorative net, so the
    /// actual affordance was invisible until someone ran the app. Giving
    /// the zone grid a distinctly stronger opacity and a dash style up
    /// front, rather than after visual inspection, is deliberate.
    private func drawZoneGrid(in context: inout GraphicsContext, size: CGSize) {
        var grid = path(for: geometry.line(atDistanceInMeters: geometry.nineMeterLine), in: size)
        for ray in geometry.sectorBoundaryRays {
            grid.addPath(path(for: ray, in: size))
        }
        context.stroke(
            grid,
            with: .color(.secondary.opacity(0.75)),
            style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
        )
    }

    /// The 7 m mark, filled as EXACTLY `geometry.sevenMeterMarkRegion` —
    /// what you see is what you tap, the same rule `GoalView.drawFrame`
    /// states for the post. A stroke centred on the region's edge would
    /// repeat the exact mistake that made the painted goalpost record
    /// taps as inside the frame.
    private func drawSevenMeterMark(in context: inout GraphicsContext, size: CGSize) {
        let rect = pixelRect(for: geometry.sevenMeterMarkRegion, in: size)
        context.fill(Path(rect), with: .color(Color(.systemOrange).opacity(0.45)))
    }

    /// Fills the region the currently `selection`ed origin corresponds to.
    /// Drawn after the zone grid, 6 m/9 m lines and 7 m mark, so the
    /// translucent highlight sits on top of them (still legible through it,
    /// same opacity as `drawSevenMeterMark`'s own fill) — but before
    /// `drawOutline`/`drawGoalMouth`, so those crisp boundary strokes stay
    /// on top of the highlight rather than getting tinted themselves.
    ///
    /// `.sevenMeters` reuses `geometry.sevenMeterMarkRegion` — the exact
    /// rect `drawSevenMeterMark` already fills and `origin(at:)` already
    /// hit-tests against. `.zone(z)` highlights `geometry.shape(for: z)`,
    /// the closed polygon `zone(at:)` classifies as that zone; `shape(for:)`
    /// does not repeat its first point, so `closeSubpath()` is what closes
    /// it here, connecting the last point back to the first as its own
    /// header comment documents.
    private func drawSelectionHighlight(in context: inout GraphicsContext, size: CGSize) {
        guard let selection else { return }

        switch selection {
        case .sevenMeters:
            let rect = pixelRect(for: geometry.sevenMeterMarkRegion, in: size)
            context.fill(Path(rect), with: .color(selectionHighlightColor))
        case .zone(let zone):
            var shape = path(for: geometry.shape(for: zone), in: size)
            shape.closeSubpath()
            context.fill(shape, with: .color(selectionHighlightColor))
        }
    }

    // MARK: - Hit-testing

    /// The single place a tap's view-pixel location becomes a normalized
    /// `CourtPoint` — the exact inverse of `pixelPoint(for:in:)`. Unlike
    /// `GoalView`'s `mouthPoint(fromViewLocation:canvasSize:)`,
    /// `CourtPoint`'s own `0...1` clamping is exactly right to keep here:
    /// there is no "off court" meaning to preserve (see `CourtPoint`'s
    /// header comment), so a tap beyond the drawn court simply resolves to
    /// the nearest real court position instead of needing an unbounded
    /// point type.
    private func courtPoint(fromViewLocation location: CGPoint, canvasSize: CGSize) -> CourtPoint {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return CourtPoint(x: 0.5, y: 0.5) }
        return CourtPoint(x: location.x / canvasSize.width, y: location.y / canvasSize.height)
    }

    private func handleTap(at location: CGPoint, canvasSize: CGSize) {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return }
        let point = courtPoint(fromViewLocation: location, canvasSize: canvasSize)
        let origin = geometry.origin(at: point)
        onOriginTapped(origin)
    }
}

#Preview("CourtView") {
    CourtView { origin in
        print("Tapped: \(origin.code)")
    }
    .padding()
}

#Preview("CourtView - Dark") {
    CourtView { origin in
        print("Tapped: \(origin.code)")
    }
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("CourtView - Selected") {
    CourtView(selection: .zone(CourtZone(sector: .leftWing, depth: .near))) { origin in
        print("Tapped: \(origin.code)")
    }
    .padding()
}

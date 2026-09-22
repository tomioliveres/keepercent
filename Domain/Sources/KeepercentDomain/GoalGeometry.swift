// GoalGeometry converts a raw normalized goal tap into the real handball
// goal-mouth geometry (in metres) and derives a GoalTarget from it. It also
// exposes the normalized layout (`region(for:)`) that the view draws from,
// so drawing and hit-testing are derived from the same constants and cannot
// drift apart.
//
// Perspective: the shooter's point of view, facing the goal. See the header
// comment of GoalTarget.swift and docs/mvp.md §5.1 for the product-level
// description.

import Foundation

/// The raw normalized tap point on the drawn goal area, as recorded by the
/// view layer, anchored to the goal MOUTH itself.
///
/// - `x`: 0 = the inner edge of the shooter's LEFT post, 1 = the inner edge
///   of the shooter's RIGHT post.
/// - `y`: 0 = the underside of the crossbar, 1 = the ground line.
///
/// This is the value that gets persisted: targets are always *derived* from
/// it (see `GoalGeometry.target(at:)`), never stored directly, so the
/// boundaries can be redefined later without losing data — the same
/// contract `CourtPoint` follows for the court.
///
/// CRITICAL contrast with `CourtPoint`: `CourtPoint` clamps to `0...1`
/// because every out-of-range court tap means the same thing ("a drag
/// ended outside the drawn canvas, but the shot still landed *somewhere*
/// on the court"). A `GoalPoint` is different: `x`/`y` outside `0...1` are
/// not noise to be clamped away — they are exactly what "hit the frame"
/// (a fraction of a post-width outside the mouth) and "missed the goal"
/// (well outside it) look like. Clamping a `GoalPoint` would silently turn
/// every post hit and every miss into a zone inside the goal, destroying
/// the information `target(at:)` needs. So `GoalPoint` stores `x`/`y`
/// verbatim and lets `GoalGeometry.target(at:)` interpret the full range.
public struct GoalPoint: Equatable, Hashable, Sendable {
    public let x: Double
    public let y: Double

    /// A NaN coordinate still carries no usable position information, the
    /// same problem `CourtPoint` resolves by substituting the midpoint of
    /// its `0...1` range. `GoalPoint` has no such range to clamp into, but
    /// `0.5` remains the defensible, documented resolution: it is the
    /// centre of the goal mouth, the same "no information, assume the most
    /// neutral spot" answer `CourtPoint` gives, applied to the one range
    /// that is actually meaningful here (the mouth itself). Any other
    /// resolution (e.g. 0, or leaving NaN in place) would either bias the
    /// result toward a specific post/corner or let NaN escape into the
    /// comparisons in `target(at:)`, where it compares false against every
    /// bound and would misclassify as a miss.
    public init(x: Double, y: Double) {
        self.x = Self.resolvedCoordinate(x)
        self.y = Self.resolvedCoordinate(y)
    }

    private static func resolvedCoordinate(_ value: Double) -> Double {
        value.isNaN ? 0.5 : value
    }
}

/// A normalized rectangle in the same frame as `GoalPoint` (`x`/`y` = 0 at
/// the left post / crossbar underside, 1 at the right post / ground line).
/// Used only to hand the view the layout it should draw — no CoreGraphics,
/// no SwiftUI, so the domain stays a pure Swift package.
public struct GoalRegion: Equatable, Hashable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

/// The real handball goal, in metres, used to derive a `GoalTarget` from a
/// normalized `GoalPoint`, and to expose the matching `GoalRegion` layout
/// for drawing.
public struct GoalGeometry: Equatable, Hashable, Sendable {
    /// The goal mouth width (the regulation handball goal is 3 m wide).
    public let widthInMeters: Double
    /// The goal mouth height (the regulation handball goal is 2 m tall).
    public let heightInMeters: Double
    /// The thickness of the post/crossbar HIT band, measured outward from
    /// the mouth edge, in metres.
    ///
    /// This is deliberately larger than the stroke the view actually draws
    /// for the post/crossbar: a real post reads as a thin line on screen,
    /// but hit-testing against that thin line would make "aim for the
    /// post" require pixel-perfect accuracy. 0.25 m is the default: next to
    /// a 3 m mouth, a quarter of a metre of real goal reads as a
    /// comfortable finger-sized touch target (roughly 8% of the mouth
    /// width per side) without eating meaningfully into the "inside the
    /// frame" thirds next to it. The view draws its visible stroke thinner
    /// than this and uses `normalizedFrameBandThicknessX/Y` to know how
    /// far outside the mouth the invisible hit area actually extends.
    public let frameBandInMeters: Double

    public init(
        widthInMeters: Double = 3,
        heightInMeters: Double = 2,
        frameBandInMeters: Double = 0.25
    ) {
        // A zero or negative mouth dimension is a programmer error, not a
        // legitimate geometry: `normalizedFrameBandThicknessX/Y` would
        // divide by it and yield infinity, which then compares true
        // against every band-membership check in `target(at:)` — so the
        // failure mode is not a crash, it is that EVERY tap silently
        // resolves as a frame-band hit, corrupting every recorded shot
        // from then on. A negative frame band is equally nonsensical (a
        // hit band with negative thickness). Trapping here, at
        // construction, is strictly better than that quiet wrong answer:
        // it surfaces the bug at the one call site that built the bad
        // geometry, instead of silently mis-scoring whatever shot
        // happens to be tapped next.
        precondition(widthInMeters > 0, "GoalGeometry.widthInMeters must be positive")
        precondition(heightInMeters > 0, "GoalGeometry.heightInMeters must be positive")
        precondition(frameBandInMeters >= 0, "GoalGeometry.frameBandInMeters must not be negative")
        self.widthInMeters = widthInMeters
        self.heightInMeters = heightInMeters
        self.frameBandInMeters = frameBandInMeters
    }

    public static let standard = GoalGeometry()
}

extension GoalGeometry {
    /// The post/crossbar hit band's thickness, normalized to the same
    /// `0...1` mouth frame as `GoalPoint`'s `x`. The view extends its drawn
    /// goal area this far past the mouth on each side.
    public var normalizedFrameBandThicknessX: Double {
        frameBandInMeters / widthInMeters
    }

    /// The post/crossbar hit band's thickness, normalized to the same
    /// `0...1` mouth frame as `GoalPoint`'s `y`.
    public var normalizedFrameBandThicknessY: Double {
        frameBandInMeters / heightInMeters
    }

    /// Absorbs floating-point noise at the thirds boundaries (1/3, 2/3).
    ///
    /// Unlike `CourtPoint`, `GoalPoint` does not round-trip its coordinates
    /// through a lossy normalize/denormalize step, so this is not needed to
    /// undo storage noise. It is needed for a different, equally concrete
    /// reason: `region(for:)`'s center is computed via arithmetic (adding
    /// half a third's width, itself a division by 3) that can land a few
    /// ULPs off the exact rational boundary. The round-trip tests require
    /// that computed center to resolve back through `target(at:)` to the
    /// same zone/segment it came from, so the same boundary comparisons
    /// `target(at:)` uses need this tiny tolerance — the same idea
    /// `CourtGeometry` applies, applied only where there is a concrete
    /// source of noise to absorb.
    fileprivate static let boundaryTolerance: Double = 1e-9

    fileprivate static let firstThird: Double = 1.0 / 3.0
    fileprivate static let secondThird: Double = 2.0 / 3.0

    /// The ball cannot pass under the floor: a `y` beyond the ground line
    /// (1) resolves as though it landed exactly on the ground line. This is
    /// a deliberate, total resolution (not a special case) — it is applied
    /// once, up front, so every downstream comparison (post band, zone,
    /// miss direction) already sees a physically possible `y`. It only
    /// ever pulls `y` down toward 1; a `y` above the crossbar (negative)
    /// is untouched, because there is no equivalent physical ceiling.
    fileprivate func groundResolvedY(_ y: Double) -> Double {
        min(y, 1)
    }

    /// Buckets a coordinate already expressed in "thirds of the mouth"
    /// units into first/second/third, with both internal boundaries (1/3,
    /// 2/3) deliberately tie-broken to the middle bucket.
    ///
    /// This mirrors `CourtGeometry.sector(at:)`'s documented rule ("a
    /// boundary belongs to the more central sector"): with three equal
    /// buckets the middle one is the natural "center", so a tap exactly on
    /// either boundary reads as aiming at the middle third rather than
    /// arbitrarily favouring whichever bucket happens to own the `<=`.
    fileprivate func thirdIndex(_ value: Double) -> Int {
        let tolerance = Self.boundaryTolerance
        if value <= Self.firstThird - tolerance {
            return 0
        }
        if value <= Self.secondThird + tolerance {
            return 1
        }
        return 2
    }

    fileprivate func rowFor(_ y: Double) -> GoalRow {
        switch thirdIndex(y) {
        case 0: return .top
        case 1: return .middle
        default: return .bottom
        }
    }

    fileprivate func columnFor(_ x: Double) -> GoalColumn {
        switch thirdIndex(x) {
        case 0: return .left
        case 1: return .center
        default: return .right
        }
    }

    /// The post segment for a `y` already clamped into the post's own
    /// `0...1` extent — used both by `target(at:)` (where the corner rule
    /// below clamps `y` before calling this) and by `region(for:)`.
    fileprivate func postSegment(forClampedY y: Double, top: PostSegment, middle: PostSegment, bottom: PostSegment) -> PostSegment {
        switch rowFor(y) {
        case .top: return top
        case .middle: return middle
        case .bottom: return bottom
        }
    }

    fileprivate func crossbarSegment(forX x: Double) -> PostSegment {
        switch columnFor(x) {
        case .left: return .crossbarLeft
        case .center: return .crossbarCenter
        case .right: return .crossbarRight
        }
    }

    /// The target a tap resolves to: total for every `(x, y)`, including
    /// out-of-range and NaN-resolved input.
    ///
    /// Resolution order (each rule deliberate, see the comments below):
    /// 1. Frame band (post, then crossbar) — a tap on the frame itself.
    /// 2. Inside the mouth — a tap between the posts and under the bar.
    /// 3. Everything else — a miss, direction depends on which way.
    public func target(at point: GoalPoint) -> GoalTarget {
        let tolerance = Self.boundaryTolerance
        let bandX = normalizedFrameBandThicknessX
        let bandY = normalizedFrameBandThicknessY

        // Ground-line resolution applies before any other comparison: a
        // tap under the floor is treated as landing exactly on the floor.
        let y = groundResolvedY(point.y)
        let x = point.x

        // --- 1. Frame band -------------------------------------------------
        //
        // Left/right post band membership checks `x` against the band, and
        // bounds `y` between the ground line (already resolved above) and
        // the crossbar band's own outer edge, `-bandY`. That upper bound is
        // load-bearing: `region(for:)` never draws a post's hit area any
        // further up than `-bandY` (see `region(for: PostSegment)` below),
        // so a tap further up than that must not hit-test as the post
        // either — otherwise drawing and hit-testing would disagree about
        // where the post's area ends, exactly what `region(for:)` exists to
        // prevent. Bounding at precisely `-bandY`, rather than at `0` (the
        // mouth edge) or leaving it unbounded, keeps the corner square
        // (`x` in the post band, `y` in `[-bandY, 0)`) inside this band, so
        // the post still owns the corner and the rule below still falls out
        // without a special case: a tap in the corner has `x` in the left
        // post's band and `y` within this same bound, so it is caught HERE,
        // before the crossbar band's mouth-restricted `x` check is even
        // considered.
        let inLeftPostBand = x >= -bandX - tolerance && x < tolerance && y >= -bandY - tolerance
        let inRightPostBand = x > 1 - tolerance && x <= 1 + bandX + tolerance && y >= -bandY - tolerance

        if inLeftPostBand {
            let clampedY = min(max(y, 0), 1)
            return .post(postSegment(forClampedY: clampedY, top: .leftPostTop, middle: .leftPostMiddle, bottom: .leftPostBottom))
        }
        if inRightPostBand {
            let clampedY = min(max(y, 0), 1)
            return .post(postSegment(forClampedY: clampedY, top: .rightPostTop, middle: .rightPostMiddle, bottom: .rightPostBottom))
        }

        // Crossbar band membership deliberately restricts `x` to INSIDE the
        // mouth (`0...1`), never past it. The crossbar spans BETWEEN the
        // posts — its three segments are defined across the mouth width —
        // while the post is the full-height member that owns the corner.
        // Restricting the crossbar's `x` this way is what makes that
        // ownership explicit: a corner tap's `x` is already claimed by a
        // post band above, so it never reaches this check at all.
        let insideMouthX = x >= -tolerance && x <= 1 + tolerance
        let inCrossbarBand = y >= -bandY - tolerance && y < tolerance

        if inCrossbarBand && insideMouthX {
            return .post(crossbarSegment(forX: x))
        }

        // --- 2. Inside the mouth --------------------------------------------
        // No upper bound on `y` here: `groundResolvedY`, applied
        // unconditionally at the top of this function, already clamped
        // `y` to `<= 1`, so that bound always holds by the time this line
        // runs. If `groundResolvedY` is ever weakened or removed, this
        // check's correctness breaks with it — a future reader changing
        // that clamp must also revisit this line.
        let insideMouthY = y >= -tolerance
        if insideMouthX && insideMouthY {
            return .inside(GoalZone(row: rowFor(y), column: columnFor(x)))
        }

        // --- 3. Everything else: a miss -------------------------------------
        //
        // Precedence: a tap that is both high AND wide resolves to
        // wideLeft/wideRight, never `.over`. `MissDirection` has no
        // combined "high and wide" case, so this has to be an explicit
        // rule rather than an emergent one: a horizontal miss is the one
        // both the shooter and the goalkeeper read first (it is the
        // direction a keeper dives), so it takes priority when a tap is
        // unambiguously off in both axes.
        //
        // "Wide" here means `x` outside the mouth's own `0...1` extent —
        // NOT merely beyond the frame band. A tap can have `x` still
        // inside the post's band width and still reach this point: that
        // happens exactly when it failed `inLeftPostBand`/`inRightPostBand`
        // on `y` alone (too far above `-bandY`, per the bound above). Such
        // a tap is both left-of-the-mouth AND above-the-frame, i.e. high
        // AND wide, so this precedence rule is exactly what must classify
        // it — and it does, with no extra branch, because "wide" is
        // defined by the mouth's `x` extent, not the narrower band.
        if x < -tolerance {
            return .out(.wideLeft)
        }
        if x > 1 + tolerance {
            return .out(.wideRight)
        }
        // The only way to reach here is `x` inside the mouth's horizontal
        // extent (already excluded by the two checks above) and `y` above
        // the crossbar band (already excluded by `inCrossbarBand` above).
        return .out(.over)
    }

    /// The normalized rect of one 3x3 inside-the-frame cell, in the SAME
    /// frame `target(at:)` reads from — derived from the same
    /// `firstThird`/`secondThird` constants, so drawing and hit-testing
    /// cannot drift apart.
    public func region(for zone: GoalZone) -> GoalRegion {
        let column = Self.thirdBounds(index: columnIndex(zone.column))
        let row = Self.thirdBounds(index: rowIndex(zone.row))
        return GoalRegion(x: column.start, y: row.start, width: column.length, height: row.length)
    }

    /// The normalized rect of one frame hit-band segment, in the SAME frame
    /// `target(at:)` reads from.
    ///
    /// The top/bottom post segments' regions extend into the corner (up to
    /// `-normalizedFrameBandThicknessY` for the top ones) rather than
    /// stopping at the mouth's own top edge (`y = 0`): the post "owns the
    /// corner" (see the corner rule in `target(at:)`), and the drawn frame
    /// needs a region covering that corner square or the view would leave
    /// a visible gap where the post and crossbar bands meet.
    public func region(for segment: PostSegment) -> GoalRegion {
        let bandX = normalizedFrameBandThicknessX
        let bandY = normalizedFrameBandThicknessY

        switch segment {
        case .leftPostTop:
            return GoalRegion(x: -bandX, y: -bandY, width: bandX, height: Self.firstThird + bandY)
        case .leftPostMiddle:
            return GoalRegion(x: -bandX, y: Self.firstThird, width: bandX, height: Self.secondThird - Self.firstThird)
        case .leftPostBottom:
            return GoalRegion(x: -bandX, y: Self.secondThird, width: bandX, height: 1 - Self.secondThird)
        case .rightPostTop:
            return GoalRegion(x: 1, y: -bandY, width: bandX, height: Self.firstThird + bandY)
        case .rightPostMiddle:
            return GoalRegion(x: 1, y: Self.firstThird, width: bandX, height: Self.secondThird - Self.firstThird)
        case .rightPostBottom:
            return GoalRegion(x: 1, y: Self.secondThird, width: bandX, height: 1 - Self.secondThird)
        case .crossbarLeft:
            return GoalRegion(x: 0, y: -bandY, width: Self.firstThird, height: bandY)
        case .crossbarCenter:
            return GoalRegion(x: Self.firstThird, y: -bandY, width: Self.secondThird - Self.firstThird, height: bandY)
        case .crossbarRight:
            return GoalRegion(x: Self.secondThird, y: -bandY, width: 1 - Self.secondThird, height: bandY)
        }
    }

    /// The normalized rects a `MissDirection` highlights, clipped to
    /// `bounds`, in the SAME frame `target(at:)` reads from.
    ///
    /// This used to return one always-correct-but-partial `GoalRegion`: a
    /// finite subset of the true, unbounded miss area (see `GoalPoint`'s
    /// header comment — `GoalPoint` deliberately never clamps, so e.g.
    /// `wideLeft` matches every `x < 0` outside the post band, however far
    /// out). That subset was a correct statement about an unbounded area,
    /// but the wrong choice for a DRAWABLE one: `GoalView` tinted exactly
    /// that small rect, so the rest of the drawn margin read as
    /// undifferentiated gray while still hit-testing as that same miss
    /// direction — a tap there recorded a miss nowhere near where the
    /// highlight would land. That is the same "what you see is what you
    /// tap" defect `GoalView.drawFrame`'s header comment documents fixing
    /// once already, for the frame band.
    ///
    /// `bounds` is the one piece of context a `GoalRegion`-returning API
    /// was missing: the true miss area has no finite extent to report
    /// without a caller-supplied drawable area to clip it to (typically
    /// the view's own canvas, in these same normalized units). Within
    /// `bounds`, the returned rects TILE exactly — every point in `bounds`
    /// that `target(at:)` resolves to this `direction` lands in exactly
    /// one of them, with no gap and no overlap — rather than the old
    /// subset's weaker "no overlap, maybe a gap" guarantee.
    ///
    /// The tiling reads directly off `target(at:)`'s own miss fallback
    /// (reached only once a point is not in a post band, not in the
    /// crossbar band, and not inside the mouth): `x < -tolerance` ->
    /// `.wideLeft`, `x > 1 + tolerance` -> `.wideRight`, else `.over`.
    /// "Wide" is the MOUTH's own `0...1` extent, not the narrower frame
    /// band, which is what makes the "high AND wide" precedence rule (see
    /// `target(at:)`'s own comment) fall out with no special case here
    /// either:
    ///
    /// - `.wideLeft` is two rects: everything left of `-bandX`, at ANY `y`
    ///   (the post band's own `x` check already excludes that column, so
    ///   `target(at:)` never resolves it to `.post` regardless of `y`) —
    ///   plus the corner strip `x` in `[-bandX, 0)` with `y < -bandY`, the
    ///   part of the left post band's `x`-range that sits above the post
    ///   band's own `y` bound (see `target(at:)`'s corner-rule comment),
    ///   which is therefore never `.post` either and falls through to
    ///   `.wideLeft`.
    /// - `.wideRight` mirrors both rects across `x = 1`.
    /// - `.over` is one rect: `x` in `0...1` (the mouth's own horizontal
    ///   extent — `target(at:)` only reaches `.over` when `x` is inside
    ///   it; outside it, the "high and wide" rule above already claimed
    ///   the point), `y < -bandY`.
    ///
    /// Each rect is clipped to `bounds`; a rect that does not intersect
    /// `bounds` at all is simply omitted, so a degenerate or very small
    /// `bounds` (e.g. one that does not reach past the frame band) can
    /// legitimately return fewer rects than usual, or none at all — that
    /// is the correct answer for "no drawable area exists there", not a
    /// fallback rect to invent.
    public func regions(for direction: MissDirection, within bounds: GoalRegion) -> [GoalRegion] {
        let bandX = normalizedFrameBandThicknessX
        let bandY = normalizedFrameBandThicknessY

        switch direction {
        case .wideLeft:
            return [
                Self.clip(maxX: -bandX, to: bounds),
                Self.clip(minX: -bandX, maxX: 0, maxY: -bandY, to: bounds)
            ].compactMap { $0 }
        case .wideRight:
            return [
                Self.clip(minX: 1 + bandX, to: bounds),
                Self.clip(minX: 1, maxX: 1 + bandX, maxY: -bandY, to: bounds)
            ].compactMap { $0 }
        case .over:
            return [
                Self.clip(minX: 0, maxX: 1, maxY: -bandY, to: bounds)
            ].compactMap { $0 }
        }
    }

    /// One call site for every `GoalTarget` case, so a caller (the view)
    /// never needs its own `switch` over `.inside`/`.post`/`.out` just to
    /// find the region(s) to highlight. `.inside`/`.post` regions are
    /// already finite — `bounds` plays no part and the list always has
    /// exactly one element; `.out` defers to `regions(for: MissDirection,
    /// within:)`, which can legitimately return fewer rects, or none, for
    /// a degenerate `bounds` (see that function's doc comment).
    public func regions(for target: GoalTarget, within bounds: GoalRegion) -> [GoalRegion] {
        switch target {
        case .inside(let zone):
            return [region(for: zone)]
        case .post(let segment):
            return [region(for: segment)]
        case .out(let direction):
            return regions(for: direction, within: bounds)
        }
    }

    /// Intersects the rectangle described by its raw edges — any left at
    /// its `infinity` default means "unbounded on this side" — with
    /// `bounds`, in the same normalized frame. Returns `nil` when the
    /// intersection is empty rather than a zero/negative-size `GoalRegion`:
    /// an empty rect is not a rect worth returning, and every caller above
    /// already `compactMap`s this away.
    ///
    /// Guards against `> x0`/`> y0` with `boundaryTolerance`, not a bare
    /// `>`: when a caller's `bounds` edge is built from the same irrational
    /// division as `bandX`/`bandY` (e.g. `-bandX` and `1 + 2 * bandX`,
    /// exactly what a "no margin past the frame" `bounds` looks like), the
    /// two do not round-trip to the exact same `Double` — `x1` can land a
    /// couple of ULPs past `x0` instead of exactly on it. A bare `>` would
    /// then return a sliver rect a few times `Double.ulpOfOne` wide, which
    /// draws nothing a person could see and tiles no `target(at:)` point a
    /// grid could ever sample, but still fails `isEmpty`. The same
    /// tolerance `target(at:)`'s own boundary comparisons already use
    /// treats that sliver as the empty intersection it actually is.
    private static func clip(
        minX: Double = -.infinity,
        minY: Double = -.infinity,
        maxX: Double = .infinity,
        maxY: Double = .infinity,
        to bounds: GoalRegion
    ) -> GoalRegion? {
        let tolerance = Self.boundaryTolerance
        let x0 = max(minX, bounds.x)
        let y0 = max(minY, bounds.y)
        let x1 = min(maxX, bounds.x + bounds.width)
        let y1 = min(maxY, bounds.y + bounds.height)
        guard x1 - x0 > tolerance, y1 - y0 > tolerance else { return nil }
        return GoalRegion(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }

    private func columnIndex(_ column: GoalColumn) -> Int {
        switch column {
        case .left: return 0
        case .center: return 1
        case .right: return 2
        }
    }

    private func rowIndex(_ row: GoalRow) -> Int {
        switch row {
        case .top: return 0
        case .middle: return 1
        case .bottom: return 2
        }
    }

    /// The `(start, length)` of one third of the `0...1` mouth extent,
    /// shared by both `target(at:)` (via `thirdIndex`) and `region(for:)`
    /// so the two can never disagree about where a boundary sits.
    private static func thirdBounds(index: Int) -> (start: Double, length: Double) {
        let boundaries = [0.0, firstThird, secondThird, 1.0]
        return (boundaries[index], boundaries[index + 1] - boundaries[index])
    }
}

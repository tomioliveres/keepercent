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
        let insideMouthY = y >= -tolerance && y <= 1 + tolerance
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

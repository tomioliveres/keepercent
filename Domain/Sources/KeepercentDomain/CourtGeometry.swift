// CourtGeometry converts a raw normalized court tap into the real handball
// half-court geometry (in metres) and derives a CourtZone from it.
//
// Perspective: the shooter's point of view, facing the goal. See
// docs/mvp.md §5.2 for the product-level description and CourtZone.swift
// for the zone/origin model this feeds.

import Foundation

/// The raw normalized tap point on the drawn court area, as recorded by the
/// view layer.
///
/// This is the value that gets persisted: zones are always *derived* from
/// it (see `CourtGeometry.zone(at:)`), never stored directly, so the zone
/// boundaries can be redefined later without losing data.
public struct CourtPoint: Equatable, Hashable, Sendable {
    /// 0 = the shooter's LEFT touchline, 1 = the shooter's RIGHT touchline.
    public let x: Double
    /// 0 = the goal line, 1 = the far edge of the drawn court area.
    public let y: Double

    /// Clamps both coordinates to `0...1`.
    ///
    /// A drag gesture can end a pixel outside the drawn canvas; clamping
    /// (rather than failing or discarding the tap) means that still records
    /// a usable shot instead of losing the data.
    ///
    /// `min`/`max` clamp `+infinity`/`-infinity` the same way they clamp
    /// any other out-of-range value, but NaN compares false against every
    /// bound, so an ordinary clamp leaves it untouched. A NaN coordinate
    /// carries no usable position information, so it is resolved to the
    /// midpoint `0.5` before clamping rather than being allowed to escape
    /// the documented `0...1` range.
    public init(x: Double, y: Double) {
        self.x = Self.clampedNormalized(x)
        self.y = Self.clampedNormalized(y)
    }

    private static func clampedNormalized(_ value: Double) -> Double {
        guard !value.isNaN else { return 0.5 }
        return min(max(value, 0), 1)
    }
}

/// A normalized rectangle in the same frame as `CourtPoint` (`x` = 0 at the
/// shooter's left touchline, `y` = 0 at the goal line). Used only to hand
/// the view a layout it should draw — no CoreGraphics, no SwiftUI, the same
/// contract `GoalRegion` follows for the goal.
public struct CourtRegion: Equatable, Hashable, Sendable {
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

/// Two normalized `CourtPoint`s a view can stroke as a line — a sector cut
/// fanning out from the goal, or the goal mouth itself.
public struct CourtSegment: Equatable, Hashable, Sendable {
    public let from: CourtPoint
    public let to: CourtPoint

    public init(from: CourtPoint, to: CourtPoint) {
        self.from = from
        self.to = to
    }
}

/// The real handball half-court, in metres, used to derive a `CourtZone`
/// from a normalized `CourtPoint`.
public struct CourtGeometry: Equatable, Hashable, Sendable {
    /// The full court width.
    public let widthInMeters: Double
    /// The depth of the drawn area, measured from the goal line.
    public let depthInMeters: Double
    /// The width of the goal itself.
    public let goalWidthInMeters: Double
    /// Distance of the 6 m line from the goal mouth; points inside it are invalid origins.
    public let sixMeterLine: Double
    /// Distance of the 9 m line from the goal mouth; this is the near/far
    /// depth boundary.
    public let nineMeterLine: Double
    /// Distance of the 7 m mark from the goal line.
    public let sevenMeterMark: Double
    /// Width of the 7 m mark's tap/hit area, in metres, centred on
    /// `sevenMeterPoint`.
    ///
    /// Wider than it is deep on purpose: left and right of the mark is
    /// still the `center` sector either way, so extra width costs nothing.
    /// See `sevenMeterMarkDepthInMeters` for why depth is the dimension
    /// that actually needs to stay tight.
    public let sevenMeterMarkWidthInMeters: Double
    /// Depth of the 7 m mark's tap/hit area, in metres, centred on
    /// `sevenMeterPoint`.
    ///
    /// Kept deliberately shallow (1.0 m, i.e. 6.5 m…7.5 m for the default
    /// 7 m mark): depth is where the competing shots live. A pivot shoots
    /// from on or just above the 6 m line, a few metres from the mark, and
    /// a disc large enough to be a comfortable tap target would swallow
    /// those pivot shots and mis-record them as penalties. 1.0 m deep stays
    /// clear of both the 6 m area and the 9 m line.
    public let sevenMeterMarkDepthInMeters: Double

    public init(
        widthInMeters: Double = 20,
        depthInMeters: Double = 15,
        goalWidthInMeters: Double = 3,
        sixMeterLine: Double = 6,
        nineMeterLine: Double = 9,
        sevenMeterMark: Double = 7,
        sevenMeterMarkWidthInMeters: Double = 1.4,
        sevenMeterMarkDepthInMeters: Double = 1.0
    ) {
        // A zero or negative dimension makes every derivation below return a
        // plausible-looking wrong answer instead of failing: a zero width
        // collapses `xMeters` to 0, so every tap on the court reads as the
        // `center` sector and every recorded shot is silently misattributed.
        // The same reasoning as `GoalGeometry.init` — a trap is loud and
        // correct where the quiet answer corrupts the data.
        precondition(widthInMeters > 0, "CourtGeometry.widthInMeters must be positive")
        precondition(depthInMeters > 0, "CourtGeometry.depthInMeters must be positive")
        precondition(goalWidthInMeters > 0, "CourtGeometry.goalWidthInMeters must be positive")
        precondition(sevenMeterMarkWidthInMeters > 0, "CourtGeometry.sevenMeterMarkWidthInMeters must be positive")
        precondition(sevenMeterMarkDepthInMeters > 0, "CourtGeometry.sevenMeterMarkDepthInMeters must be positive")
        self.widthInMeters = widthInMeters
        self.depthInMeters = depthInMeters
        self.goalWidthInMeters = goalWidthInMeters
        self.sixMeterLine = sixMeterLine
        self.nineMeterLine = nineMeterLine
        self.sevenMeterMark = sevenMeterMark
        self.sevenMeterMarkWidthInMeters = sevenMeterMarkWidthInMeters
        self.sevenMeterMarkDepthInMeters = sevenMeterMarkDepthInMeters
    }

    public static let standard = CourtGeometry()
}

extension CourtGeometry {
    /// The metric frame used by the derivation below has its origin at the
    /// goal centre, on the goal line, with `x` positive toward the
    /// shooter's right and `y` positive away from the goal, into the court.
    func xMeters(for point: CourtPoint) -> Double {
        (point.x - 0.5) * widthInMeters
    }

    func yMeters(for point: CourtPoint) -> Double {
        point.y * depthInMeters
    }

    /// The signed angle, in degrees, at the goal centre between the axis
    /// running straight out of the goal and the tap, positive toward the
    /// shooter's right. In range `-90...90` for the on-court points this
    /// domain deals with (`yMeters >= 0`).
    func angleDegrees(for point: CourtPoint) -> Double {
        atan2(xMeters(for: point), yMeters(for: point)) * 180 / .pi
    }

    /// The distance, in metres, from the tap to the nearest point of the
    /// goal mouth segment (the 3 m line between the posts) — not to the
    /// goal centre.
    ///
    /// The real 9 m line is not a semicircle: it is two quarter circles
    /// centred on the posts, joined by a straight segment parallel to the
    /// goal line. That shape is exactly the locus of points 9 m away from
    /// the goal mouth segment, so measuring distance to that segment (by
    /// clamping the tap's x-offset onto the segment's extent before taking
    /// the distance) makes the derived depth agree exactly with the 9 m
    /// line as drawn. A circle centred on the goal centre would disagree
    /// with that drawing near the posts.
    func distanceToGoalMouth(for point: CourtPoint) -> Double {
        let x = xMeters(for: point)
        let y = yMeters(for: point)
        let halfGoal = goalWidthInMeters / 2
        let nearestX = min(max(x, -halfGoal), halfGoal)
        return hypot(x - nearestX, y)
    }

    /// The sector a tap falls into, from an even 5-way split of the angle
    /// at the goal centre (36 degrees each): center, then back, then wing
    /// on either side.
    ///
    /// The cuts sit at 18 and 54 degrees rather than at multiples of 36,
    /// because an even split centred on 0 degrees lands its boundaries
    /// close to the real playing positions: a wing at the 6 m-line corner
    /// sits near 74 degrees, a back near 29 degrees, the centre near 0.
    ///
    /// A boundary angle belongs to the more central sector: this is a
    /// deliberate tie-break (`<=`, not `<`), not an accident.
    ///
    /// The comparison carries a tiny epsilon to absorb floating-point
    /// round-trip noise: `CourtPoint` stores a normalized `0...1`
    /// coordinate, so a tap meant to land exactly on a boundary angle can
    /// come back a few `1e-14` degrees off after normalizing and
    /// denormalizing. Without the epsilon that noise could flip which side
    /// of the boundary an intentionally-on-the-line tap falls on.
    public func sector(at point: CourtPoint) -> CourtSector {
        let angle = angleDegrees(for: point)
        let magnitude = abs(angle)

        if magnitude <= Self.centerBoundaryDegrees + Self.boundaryToleranceDegrees {
            return .center
        }
        if magnitude <= Self.backBoundaryDegrees + Self.boundaryToleranceDegrees {
            return angle < 0 ? .leftBack : .rightBack
        }
        return angle < 0 ? .leftWing : .rightWing
    }

    /// The center/back cut, in degrees either side of straight-ahead. Named
    /// so `sectorBoundaryRays` can derive its rays from the exact same
    /// value `sector(at:)` classifies against, instead of retyping the
    /// literal in a second place.
    private static let centerBoundaryDegrees: Double = 18

    /// The back/wing cut, in degrees either side of straight-ahead. Same
    /// reasoning as `centerBoundaryDegrees`.
    private static let backBoundaryDegrees: Double = 54

    /// The depth band outside the 6 m goal area. Exactly 6 m belongs to
    /// `.near`; points inside it are not legal take-off points.
    public func depth(at point: CourtPoint) -> CourtDepth? {
        let distance = distanceToGoalMouth(for: point)
        guard distance >= sixMeterLine - Self.boundaryToleranceMeters else { return nil }
        return distance <= nineMeterLine + Self.boundaryToleranceMeters ? .near : .far
    }

    /// Absorbs floating-point round-trip noise (normalize/denormalize
    /// through `CourtPoint`'s `0...1` storage) at the sector angle
    /// boundaries, without meaningfully moving them: real taps differ from
    /// a boundary by far more than this.
    private static let boundaryToleranceDegrees: Double = 1e-9

    /// Absorbs floating-point round-trip noise at the depth boundary, for
    /// the same reason as `boundaryToleranceDegrees`.
    private static let boundaryToleranceMeters: Double = 1e-9

    /// Combines sector and depth; no zone exists inside the goal area.
    public func zone(at point: CourtPoint) -> CourtZone? {
        guard let depth = depth(at: point) else { return nil }
        return CourtZone(sector: sector(at: point), depth: depth)
    }

    /// The normalized location of the 7 m mark, for drawing and hit-testing
    /// in the view layer.
    public var sevenMeterPoint: CourtPoint {
        CourtPoint(x: 0.5, y: sevenMeterMark / depthInMeters)
    }

    /// Width-to-depth ratio of the drawn court area.
    ///
    /// Normalized x and y do NOT span the same number of metres (20 m
    /// across by 15 m deep, by default): drawing both axes with one shared
    /// scale would squash the court. A view multiplies its available
    /// height by this ratio (or divides its width by it) to get back a
    /// metrically correct drawing rect, the same trap `GoalGeometry`'s 3 m
    /// x 2 m mouth would hit without doing the equivalent.
    public var aspectRatio: Double {
        widthInMeters / depthInMeters
    }

    /// Converts a point already expressed in the goal-centred metric frame
    /// (see `xMeters(for:)`/`yMeters(for:)`) back into a normalized
    /// `CourtPoint` — the exact inverse of those two functions, so a value
    /// built from metres and a value read back via `xMeters`/`yMeters`
    /// round-trip losslessly (up to the same float noise `CourtPoint`'s own
    /// `0...1` storage always carries).
    private func normalizedPoint(xMeters x: Double, yMeters y: Double) -> CourtPoint {
        CourtPoint(x: x / widthInMeters + 0.5, y: y / depthInMeters)
    }

    /// The drawable polyline for the line `d` metres from the goal mouth —
    /// the shape `distanceToGoalMouth(for:)` and therefore `depth(at:)`
    /// actually test against, generated from that SAME definition (two
    /// quarter circles centred on the posts, radius `d`, joined by a
    /// straight segment parallel to the goal line) so the drawn line and
    /// the hit-tested boundary can never disagree.
    ///
    /// Points are ordered continuously from one touchline side to the
    /// other, so a `Path` can stroke the result directly. A part of the
    /// shape that would fall outside the drawn court (past a touchline, or
    /// past the drawn depth) is left out rather than folded back onto the
    /// boundary — `CourtPoint`'s own clamping would otherwise turn "the
    /// line left the court" into "the line runs back along the edge",
    /// silently corrupting the shape.
    ///
    /// `d <= 0` has no meaningful shape and returns an empty polyline.
    public func line(atDistanceInMeters d: Double) -> [CourtPoint] {
        guard d > 0 else { return [] }

        let halfGoal = goalWidthInMeters / 2
        let halfWidth = widthInMeters / 2

        // `phi` parametrizes each quarter arc: `phi = 0` is its top, where
        // it meets the straight segment; `phi = 90` is level with the goal
        // line, out past the post. `phiHigh`/`phiLow` clip that `0...90`
        // sweep to wherever the arc actually stays inside the drawn court —
        // `phiHigh` where it would cross a touchline, `phiLow` where it
        // would cross the far depth edge (only relevant for a `d` deeper
        // than `depthInMeters`, never for the app's own 6 m/9 m lines).
        let widthRatio = (halfWidth - halfGoal) / d
        let phiHigh: Double = widthRatio >= 1 ? 90 : asin(max(0, widthRatio)) * 180 / .pi

        let depthRatio = depthInMeters / d
        let phiLow: Double = depthRatio >= 1 ? 0 : acos(max(0, min(1, depthRatio))) * 180 / .pi

        guard phiLow < phiHigh else { return [] }

        let leftArc = quarterArcPoints(postXMeters: -halfGoal, phiLow: phiLow, phiHigh: phiHigh, distance: d, ascending: false)
        let rightArc = quarterArcPoints(postXMeters: halfGoal, phiLow: phiLow, phiHigh: phiHigh, distance: d, ascending: true)

        // The straight segment only exists when both arcs reach all the way
        // down to phi = 0, i.e. the line's depth is inside the drawn court.
        // When it is clipped by the depth edge instead (phiLow > 0), the
        // two arcs stand on their own with a genuine gap between them,
        // where the line would run beyond the drawn area.
        guard phiLow == 0 else { return leftArc + rightArc }

        let straight = straightSegmentPoints(
            fromXMeters: -min(halfGoal, halfWidth),
            toXMeters: min(halfGoal, halfWidth),
            yMeters: d
        )
        return leftArc + straight + rightArc
    }

    /// Samples one quarter arc of `line(atDistanceInMeters:)`'s shape,
    /// centred on a post, at roughly 1 degree per step (finely enough to
    /// read as smooth). `postXMeters` is the post's x position (negative
    /// for the left post, positive for the right); `phiLow`/`phiHigh` are
    /// already clipped to the drawn court, see `line(atDistanceInMeters:)`.
    /// `ascending` orders the samples from `phiLow` to `phiHigh` (the right
    /// arc, straight segment outward to the touchline) or from `phiHigh`
    /// down to `phiLow` (the left arc, touchline inward to the straight
    /// segment) so the two arcs and the segment between them read as one
    /// continuous path.
    private func quarterArcPoints(postXMeters: Double, phiLow: Double, phiHigh: Double, distance d: Double, ascending: Bool) -> [CourtPoint] {
        guard phiHigh > phiLow else { return [] }
        let sign: Double = postXMeters < 0 ? -1 : 1
        let steps = max(1, Int((phiHigh - phiLow).rounded()))
        return (0...steps).map { i in
            let t = Double(i) / Double(steps)
            let phi = ascending ? phiLow + (phiHigh - phiLow) * t : phiHigh - (phiHigh - phiLow) * t
            let radians = phi * .pi / 180
            let x = postXMeters + sign * d * sin(radians)
            let y = d * cos(radians)
            return normalizedPoint(xMeters: x, yMeters: y)
        }
    }

    /// Samples the straight middle segment of `line(atDistanceInMeters:)`'s
    /// shape, subdividing it so no single step is longer than half a metre
    /// — comparable to the quarter arcs' own step length, so a caller
    /// checking for an unexpectedly large jump between consecutive points
    /// sees one uniform bound rather than needing to special-case the one
    /// legitimately-straight run.
    private func straightSegmentPoints(fromXMeters startX: Double, toXMeters endX: Double, yMeters y: Double) -> [CourtPoint] {
        guard endX > startX else { return [normalizedPoint(xMeters: startX, yMeters: y)] }
        let maxStepLength = 0.5
        let length = endX - startX
        let steps = max(1, Int((length / maxStepLength).rounded(.up)))
        return (0...steps).map { i in
            let x = startX + length * Double(i) / Double(steps)
            return normalizedPoint(xMeters: x, yMeters: y)
        }
    }

    /// The four rays cutting the five `CourtSector`s apart, from the goal
    /// centre out to wherever they leave the drawn court — derived from the
    /// SAME `centerBoundaryDegrees`/`backBoundaryDegrees` constants
    /// `sector(at:)` classifies against, so drawing and hit-testing can
    /// never disagree about where a cut sits.
    public var sectorBoundaryRays: [CourtSegment] {
        let goalCentre = CourtPoint(x: 0.5, y: 0)
        let angles = [
            Self.centerBoundaryDegrees, -Self.centerBoundaryDegrees,
            Self.backBoundaryDegrees, -Self.backBoundaryDegrees
        ]
        return angles.map { CourtSegment(from: goalCentre, to: sectorRayEndpoint(atAngleDegrees: $0)) }
    }

    /// Only the playable part of each sector cut. The full rays still
    /// describe the classification boundary, but must not be drawn inside
    /// the forbidden 6 m goal area.
    public var playableSectorBoundaryRays: [CourtSegment] {
        sectorBoundaryRays.map { ray in
            let angle = angleDegrees(for: ray.to)
            let radius = radiusAtGoalMouthDistance(angleDegrees: angle, distance: sixMeterLine)
            let radians = angle * .pi / 180
            return CourtSegment(
                from: normalizedPoint(xMeters: radius * sin(radians), yMeters: radius * cos(radians)),
                to: ray.to
            )
        }
    }

    /// Where a ray from the goal centre, at `angle` degrees off
    /// straight-ahead, leaves the drawn court — whichever of a touchline or
    /// the far depth edge it reaches first.
    private func sectorRayEndpoint(atAngleDegrees angle: Double) -> CourtPoint {
        let radians = angle * .pi / 180
        let halfWidth = widthInMeters / 2
        let sinValue = sin(radians)
        let cosValue = cos(radians)

        // Distance along the ray (from the goal centre) at which x reaches
        // a touchline, respectively y reaches the far depth edge. A ray
        // that runs parallel to one of those edges never reaches it.
        let distanceToTouchline = abs(sinValue) > 1e-12 ? halfWidth / abs(sinValue) : .infinity
        let distanceToFarEdge = cosValue > 1e-12 ? depthInMeters / cosValue : .infinity

        let distance = min(distanceToTouchline, distanceToFarEdge)
        return normalizedPoint(xMeters: distance * sinValue, yMeters: distance * cosValue)
    }

    /// The goal mouth itself, as a drawable segment from the shooter's left
    /// post to the shooter's right post, on the goal line.
    public var goalMouth: CourtSegment {
        let halfGoal = goalWidthInMeters / 2
        return CourtSegment(
            from: normalizedPoint(xMeters: -halfGoal, yMeters: 0),
            to: normalizedPoint(xMeters: halfGoal, yMeters: 0)
        )
    }

    /// The 7 m mark's tap/hit area, in the SAME normalized frame a view
    /// draws from — so the view can fill exactly the rectangle this type
    /// hit-tests against, the same "what you see is what you tap"
    /// contract `GoalGeometry.region(for:)` follows for the goal. Nothing
    /// else defines this rectangle: `origin(at:)` reads it back from here
    /// rather than recomputing it, so the two can never drift apart.
    public var sevenMeterMarkRegion: CourtRegion {
        let halfWidth = sevenMeterMarkWidthInMeters / 2
        let halfDepth = sevenMeterMarkDepthInMeters / 2
        return CourtRegion(
            x: 0.5 - halfWidth / widthInMeters,
            y: (sevenMeterMark - halfDepth) / depthInMeters,
            width: sevenMeterMarkWidthInMeters / widthInMeters,
            height: sevenMeterMarkDepthInMeters / depthInMeters
        )
    }

    /// Where a shot originates: the single entry point a view calls to
    /// resolve a raw tap. `.sevenMeters` when the tap lands inside
    /// `sevenMeterMarkRegion` (boundary-inclusive, the same tie-break
    /// direction as `sector(at:)`/`depth(at:)`), otherwise the ordinary
    /// zone from `zone(at:)`. A tap inside 6 m returns nil.
    public func origin(at point: CourtPoint) -> ShotOrigin? {
        guard let zone = zone(at: point) else { return nil }
        let region = sevenMeterMarkRegion
        let tolerance = Self.boundaryToleranceNormalized
        let insideX = point.x >= region.x - tolerance && point.x <= region.x + region.width + tolerance
        let insideY = point.y >= region.y - tolerance && point.y <= region.y + region.height + tolerance
        if insideX && insideY {
            return .sevenMeters
        }
        return .zone(zone)
    }

    /// Absorbs floating-point round-trip noise at the 7 m mark rectangle's
    /// edges, for the same reason as `boundaryToleranceDegrees`/
    /// `boundaryToleranceMeters` — comparisons here are already in
    /// normalized units, so no further conversion applies, but the
    /// round-trip noise through `CourtPoint`'s own storage is the same.
    private static let boundaryToleranceNormalized: Double = 1e-9
}

extension CourtGeometry {
    /// The two angle bounds (degrees, `angleDegrees(for:)`'s own
    /// convention) a `CourtSector` occupies, from the SAME
    /// `centerBoundaryDegrees`/`backBoundaryDegrees` constants
    /// `sector(at:)` classifies against — never a re-typed 18/54 literal.
    /// The outer wing bound is the mathematical extreme `atan2` can reach
    /// for an on-court point (`y >= 0`), never a ray: see `shape(for:)`'s
    /// header comment for why a wing has no such ray.
    private static func angleBoundsDegrees(for sector: CourtSector) -> (low: Double, high: Double) {
        switch sector {
        case .leftWing: return (-90, -backBoundaryDegrees)
        case .leftBack: return (-backBoundaryDegrees, -centerBoundaryDegrees)
        case .center: return (-centerBoundaryDegrees, centerBoundaryDegrees)
        case .rightBack: return (centerBoundaryDegrees, backBoundaryDegrees)
        case .rightWing: return (backBoundaryDegrees, 90)
        }
    }

    /// The distance `r`, along the ray at `angle` degrees from the goal
    /// centre, at which that ray crosses `distanceToGoalMouth == distance`
    /// — i.e. the exact same equation `distanceToGoalMouth(for:)` (and
    /// therefore `depth(at:)`) evaluates, solved for `r` instead of
    /// sampled, so a point at this radius always agrees with `depth(at:)`
    /// about which side of `distance` it falls on.
    ///
    /// Mirrors `distanceToGoalMouth(for:)`'s own two cases: while the
    /// ray's horizontal offset stays within the goal mouth's own half
    /// width, the nearest point on the mouth segment is directly ahead, so
    /// distance is just the forward offset (`r * cos(angle)`); beyond it,
    /// the nearest point is the fixed post, and distance is the
    /// hypotenuse to that point, giving a quadratic in `r`. Returns
    /// `.infinity` when `distance` is smaller than the post's own offset
    /// at this angle (no positive `r` reaches it) — for the 9 m line this
    /// never happens with any plausible geometry, but the fallback keeps
    /// `min(_:courtExitRadius:)` callers correct regardless.
    private func radiusAtGoalMouthDistance(angleDegrees angle: Double, distance: Double) -> Double {
        let radians = angle * .pi / 180
        let sinValue = sin(radians)
        let cosValue = cos(radians)
        let halfGoal = goalWidthInMeters / 2

        if abs(cosValue) > 1e-12 {
            let straightR = distance / cosValue
            if straightR >= 0, abs(straightR * sinValue) <= halfGoal + Self.boundaryToleranceMeters {
                return straightR
            }
        }

        let postX = sinValue < 0 ? -halfGoal : halfGoal
        // Solving `(r*sinValue - postX)^2 + (r*cosValue)^2 = distance^2`
        // for `r`, the same distance-to-a-fixed-point equation
        // `distanceToGoalMouth(for:)` falls back to once the nearest mouth
        // point clamps to a post.
        let linearCoefficient = sinValue * postX
        let discriminant = distance * distance - postX * postX * cosValue * cosValue
        guard discriminant >= 0 else { return .infinity }
        return max(0, linearCoefficient + discriminant.squareRoot())
    }

    /// The distance, along the ray at `angle` degrees from the goal
    /// centre, to wherever that ray leaves the drawn court — reusing
    /// `sectorRayEndpoint(atAngleDegrees:)` (the exact function
    /// `sectorBoundaryRays` itself draws from) rather than recomputing the
    /// touchline/far-edge distances a second time.
    private func courtExitRadius(atAngleDegrees angle: Double) -> Double {
        let endpoint = sectorRayEndpoint(atAngleDegrees: angle)
        return hypot(xMeters(for: endpoint), yMeters(for: endpoint))
    }

    /// Samples the arc at radius `radius(angle)` for `angle` swept from
    /// `angleLow` to `angleHigh`, roughly 1 degree per step (the same
    /// sampling density `quarterArcPoints` uses for the drawn 6 m/9 m
    /// lines), PLUS every angle in `criticalAngles` that falls strictly
    /// inside `angleLow...angleHigh` — the shared building block
    /// `shape(for:)` uses for both a zone's near-side and far-side
    /// boundary.
    ///
    /// `radius` is piecewise (a `min(...)` of several sub-functions, each
    /// possibly itself a `min(...)`): a uniform angle grid samples each
    /// piece smoothly but almost never lands exactly on the angle where two
    /// pieces meet, so the chord between the two samples straddling that
    /// join cuts the corner off instead of passing through it. Forcing
    /// every join's exact angle to itself be a sample point turns that
    /// corner into an actual vertex, leaving only the unavoidable
    /// chord-vs-arc error (the sagitta) on a genuinely curved piece — see
    /// `shape(for:)`'s own critical-angle derivations for what each one
    /// joins and why closed-form angles are cheap here while the
    /// near/far-vs-court-exit join is not.
    private func radialArcPoints(angleLow: Double, angleHigh: Double, criticalAngles: [Double] = [], radius: (Double) -> Double) -> [CourtPoint] {
        guard angleHigh > angleLow else { return [] }
        let steps = max(1, Int((angleHigh - angleLow).rounded()))
        let uniformAngles = (0...steps).map { i in
            angleLow + (angleHigh - angleLow) * Double(i) / Double(steps)
        }
        let insideCriticalAngles = criticalAngles.filter { $0 > angleLow && $0 < angleHigh }
        let angles = Set(uniformAngles + insideCriticalAngles).sorted()
        return angles.map { angle in
            let r = max(0, radius(angle))
            let radians = angle * .pi / 180
            return normalizedPoint(xMeters: r * sin(radians), yMeters: r * cos(radians))
        }
    }

    /// The angle, in degrees off straight-ahead, where `courtExitRadius`'s
    /// own `min(...)` switches which edge is closer — the touchline
    /// (`halfWidth / |sin|`) and the far depth edge (`depthInMeters /
    /// cos`) are equal exactly where `tan(angle) == halfWidth /
    /// depthInMeters`, i.e. at `atan2(halfWidth, depthInMeters)`. Below
    /// this angle the touchline is farther away (the far edge wins);
    /// above it, the far edge is farther away (the touchline wins). This
    /// is the court's own physical corner, so it is the same angle on
    /// both sides of straight-ahead — callers add `±` as needed.
    private func cornerAngleDegrees() -> Double {
        atan2(widthInMeters / 2, depthInMeters) * 180 / .pi
    }

    /// The angle, in degrees off straight-ahead, where
    /// `radiusAtGoalMouthDistance(angleDegrees:distance:)`'s own straight
    /// piece (nearest mouth point straight ahead) hands off to its arc
    /// piece (nearest mouth point is the fixed post): exactly where the
    /// straight piece's sideways reach, `distance * tan(angle)`, equals
    /// the goal's own half width, i.e. at `atan2(halfGoal, distance)`.
    /// Same reasoning as `cornerAngleDegrees()` — a closed-form `tan`
    /// equation, so the exact angle is cheap to compute rather than
    /// search for.
    private func mouthTransitionAngleDegrees(distance: Double) -> Double {
        atan2(goalWidthInMeters / 2, distance) * 180 / .pi
    }

    /// Every angle, strictly between `angleLow` and `angleHigh`, where
    /// `arcRadius` and `exitRadius` cross — i.e. where
    /// `nearFarBoundaryRadius`'s own `min(...)` switches which side wins
    /// (the 9 m curve itself, vs. the court boundary the 9 m curve would
    /// otherwise poke through). Unlike `cornerAngleDegrees()` and
    /// `mouthTransitionAngleDegrees(distance:)`, this join has no closed
    /// form: both sides are themselves piecewise, so there is no single
    /// equation to solve for the angle.
    ///
    /// Found by sampling the same roughly-1-degree grid
    /// `radialArcPoints(angleLow:angleHigh:criticalAngles:radius:)` itself
    /// walks, then bisecting wherever two adjacent samples disagree about
    /// the sign of `arcRadius - exitRadius` — that disagreement brackets
    /// exactly one crossing, because both functions are continuous. 60
    /// bisection steps roughly halve a starting bracket of at most 1
    /// degree sixty times, landing the angle far below any float noise
    /// that could matter here.
    private func nearFarExitCrossings(
        angleLow: Double,
        angleHigh: Double,
        arcRadius: (Double) -> Double,
        exitRadius: (Double) -> Double
    ) -> [Double] {
        guard angleHigh > angleLow else { return [] }
        let steps = max(1, Int((angleHigh - angleLow).rounded()))
        let grid = (0...steps).map { i in
            angleLow + (angleHigh - angleLow) * Double(i) / Double(steps)
        }

        func difference(_ angle: Double) -> Double {
            arcRadius(angle) - exitRadius(angle)
        }

        var crossings: [Double] = []
        for i in 1..<grid.count {
            var low = grid[i - 1]
            var high = grid[i]
            var lowValue = difference(low)
            let highValue = difference(high)
            guard lowValue != 0 || highValue != 0 else { continue }
            guard (lowValue < 0) != (highValue < 0) else { continue }

            for _ in 0..<60 {
                let mid = (low + high) / 2
                let midValue = difference(mid)
                if midValue == 0 {
                    low = mid
                    high = mid
                    break
                }
                if (midValue < 0) == (lowValue < 0) {
                    low = mid
                    lowValue = midValue
                } else {
                    high = mid
                }
            }
            crossings.append((low + high) / 2)
        }
        return crossings
    }

    /// The closed polygon `zone(at:)` classifies as `zone` — the area the
    /// view fills to highlight a selected court zone. The first point is
    /// NOT repeated at the end: a caller closing the shape connects the
    /// last point back to the first.
    ///
    /// Built by sweeping `zone.sector`'s angle range (from the SAME
    /// `centerBoundaryDegrees`/`backBoundaryDegrees` constants
    /// `sector(at:)` reads) and, at every angle, computing the radius
    /// where the zone's near/far boundary sits — `radiusAtGoalMouthDistance`
    /// solves the exact equation `distanceToGoalMouth(for:)` evaluates, so
    /// this can never disagree with `depth(at:)` beyond the polygon's
    /// chord-vs-arc sagitta, the way sampling the
    /// drawn `line(atDistanceInMeters:)` polyline and interpolating
    /// between its points could.
    ///
    /// At every angle the boundary radius is clamped to
    /// `courtExitRadius(atAngleDegrees:)`: this is what keeps a wing's
    /// outer edge on the court's own touchline/far edge — never a ray,
    /// exactly matching the documented rule that wings have no outer ray
    /// — and what shrinks a sector's far zone to a degenerate sliver at
    /// whichever angle its ray already leaves the court before ever
    /// reaching the 9 m line (this happens for every wing, and depends on
    /// the geometry's own proportions, never hard-coded).
    ///
    /// For `.near`, the inner boundary is the 6 m line; for `.far`,
    /// the inner boundary is the near/far boundary itself,
    /// walked back the opposite way so the outer-then-inner point list
    /// traces one continuous loop.
    public func shape(for zone: CourtZone) -> [CourtPoint] {
        let (angleLow, angleHigh) = Self.angleBoundsDegrees(for: zone.sector)
        let boundaryDistance = nineMeterLine

        func nearFarBoundaryRadius(_ angle: Double) -> Double {
            min(radiusAtGoalMouthDistance(angleDegrees: angle, distance: boundaryDistance), courtExitRadius(atAngleDegrees: angle))
        }

        // The three joins that a uniform angle grid alone would sample
        // around rather than through — see `radialArcPoints`'s header for
        // why that turns a real vertex into a cut-off corner:
        //
        // 1. `cornerAngle`/`-cornerAngle`: where `courtExitRadius` itself
        //    hands off between the touchline and the far depth edge (the
        //    court's own physical corner). Relevant to BOTH boundary
        //    functions below, because `nearFarBoundaryRadius` clamps to
        //    `courtExitRadius` too.
        // 2. `mouthTransition`/`-mouthTransition`: where
        //    `radiusAtGoalMouthDistance` hands off from the mouth-straight
        //    piece to the post-centred arc. Only meaningful for
        //    `nearFarBoundaryRadius`, since `courtExitRadius` never calls
        //    `radiusAtGoalMouthDistance`.
        // 3. `nearFarExitCrossings`: where the 9 m curve and the court's
        //    own edge cross — only meaningful for `nearFarBoundaryRadius`,
        //    for the same reason.
        let cornerAngle = cornerAngleDegrees()
        let mouthTransition = mouthTransitionAngleDegrees(distance: boundaryDistance)
        let exitCrossings = nearFarExitCrossings(
            angleLow: angleLow,
            angleHigh: angleHigh,
            arcRadius: { radiusAtGoalMouthDistance(angleDegrees: $0, distance: boundaryDistance) },
            exitRadius: { courtExitRadius(atAngleDegrees: $0) }
        )
        let nearFarCriticalAngles = [cornerAngle, -cornerAngle, mouthTransition, -mouthTransition] + exitCrossings
        let exitCriticalAngles = [cornerAngle, -cornerAngle]
        let sixMeterTransition = mouthTransitionAngleDegrees(distance: sixMeterLine)
        let sixMeterExitCrossings = nearFarExitCrossings(
            angleLow: angleLow,
            angleHigh: angleHigh,
            arcRadius: { radiusAtGoalMouthDistance(angleDegrees: $0, distance: sixMeterLine) },
            exitRadius: { courtExitRadius(atAngleDegrees: $0) }
        )
        let sixMeterCriticalAngles = [cornerAngle, -cornerAngle, sixMeterTransition, -sixMeterTransition] + sixMeterExitCrossings

        let outerRadius: (Double) -> Double
        let outerCriticalAngles: [Double]
        let innerPoints: [CourtPoint]

        switch zone.depth {
        case .near:
            outerRadius = nearFarBoundaryRadius
            outerCriticalAngles = nearFarCriticalAngles
            innerPoints = radialArcPoints(
                angleLow: angleLow,
                angleHigh: angleHigh,
                criticalAngles: sixMeterCriticalAngles,
                radius: { min(radiusAtGoalMouthDistance(angleDegrees: $0, distance: sixMeterLine), courtExitRadius(atAngleDegrees: $0)) }
            ).reversed()
        case .far:
            outerRadius = { courtExitRadius(atAngleDegrees: $0) }
            outerCriticalAngles = exitCriticalAngles
            innerPoints = radialArcPoints(
                angleLow: angleLow,
                angleHigh: angleHigh,
                criticalAngles: nearFarCriticalAngles,
                radius: nearFarBoundaryRadius
            ).reversed()
        }

        let outerPoints = radialArcPoints(
            angleLow: angleLow,
            angleHigh: angleHigh,
            criticalAngles: outerCriticalAngles,
            radius: outerRadius
        )
        return outerPoints + innerPoints
    }
}

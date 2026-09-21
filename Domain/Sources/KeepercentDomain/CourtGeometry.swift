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
    /// Distance of the 6 m line from the goal mouth, for drawing.
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

    /// The depth band a tap falls into, from its distance to the goal
    /// mouth. The boundary belongs to `.near` (docs/mvp.md describes near
    /// as "6-9m"), a deliberate tie-break, with the same floating-point
    /// round-trip tolerance as `sector(at:)`.
    public func depth(at point: CourtPoint) -> CourtDepth {
        distanceToGoalMouth(for: point) <= nineMeterLine + Self.boundaryToleranceMeters ? .near : .far
    }

    /// Absorbs floating-point round-trip noise (normalize/denormalize
    /// through `CourtPoint`'s `0...1` storage) at the sector angle
    /// boundaries, without meaningfully moving them: real taps differ from
    /// a boundary by far more than this.
    private static let boundaryToleranceDegrees: Double = 1e-9

    /// Absorbs floating-point round-trip noise at the depth boundary, for
    /// the same reason as `boundaryToleranceDegrees`.
    private static let boundaryToleranceMeters: Double = 1e-9

    /// The zone a tap falls into: the combination of `sector(at:)` and
    /// `depth(at:)`.
    ///
    /// A tap exactly at the goal centre is defined behaviour, not a
    /// special case: `atan2(0, 0) == 0` puts it in `.center`, and a
    /// distance of `0` puts it in `.near`.
    public func zone(at point: CourtPoint) -> CourtZone {
        CourtZone(sector: sector(at: point), depth: depth(at: point))
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
    /// zone from `zone(at:)`.
    public func origin(at point: CourtPoint) -> ShotOrigin {
        let region = sevenMeterMarkRegion
        let tolerance = Self.boundaryToleranceNormalized
        let insideX = point.x >= region.x - tolerance && point.x <= region.x + region.width + tolerance
        let insideY = point.y >= region.y - tolerance && point.y <= region.y + region.height + tolerance
        if insideX && insideY {
            return .sevenMeters
        }
        return .zone(zone(at: point))
    }

    /// Absorbs floating-point round-trip noise at the 7 m mark rectangle's
    /// edges, for the same reason as `boundaryToleranceDegrees`/
    /// `boundaryToleranceMeters` — comparisons here are already in
    /// normalized units, so no further conversion applies, but the
    /// round-trip noise through `CourtPoint`'s own storage is the same.
    private static let boundaryToleranceNormalized: Double = 1e-9
}

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

    public init(
        widthInMeters: Double = 20,
        depthInMeters: Double = 15,
        goalWidthInMeters: Double = 3,
        sixMeterLine: Double = 6,
        nineMeterLine: Double = 9,
        sevenMeterMark: Double = 7
    ) {
        self.widthInMeters = widthInMeters
        self.depthInMeters = depthInMeters
        self.goalWidthInMeters = goalWidthInMeters
        self.sixMeterLine = sixMeterLine
        self.nineMeterLine = nineMeterLine
        self.sevenMeterMark = sevenMeterMark
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

        if magnitude <= 18 + Self.boundaryToleranceDegrees {
            return .center
        }
        if magnitude <= 54 + Self.boundaryToleranceDegrees {
            return angle < 0 ? .leftBack : .rightBack
        }
        return angle < 0 ? .leftWing : .rightWing
    }

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
}

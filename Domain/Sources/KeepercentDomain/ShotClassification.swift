// ShotClassification derives the lateral side and vertical height of a
// shot's origin and target, and classifies the shot line between them as a
// cross-shot, a near-post shot, or neither.
//
// Perspective: always the SHOOTER's point of view, consistent with
// GoalTarget and CourtZone. This is pure derivation over `ShotOrigin` and
// `GoalTarget` values — nothing here is stored; see docs/mvp.md §5.3.

/// The lateral side of a shot's origin or target, from the shooter's
/// perspective (the shooter's left is the goalkeeper's right).
///
/// This is the shared side vocabulary `ShotClassification` compares between
/// an origin and a target to classify the shot line.
public enum ShotSide: String, CaseIterable, Equatable, Hashable, Sendable {
    case left
    case center
    case right
}

/// The vertical band of a shot target, from the shooter's perspective.
///
/// Only defined where the target's vertical position inside the goal frame
/// is actually known; see `ShotClassification.targetHeight(_:)`.
public enum ShotHeight: String, CaseIterable, Equatable, Hashable, Sendable {
    case top
    case middle
    case bottom
}

/// How a shot's line compares the origin side to the target side, from the
/// shooter's perspective. See docs/mvp.md §5.3.
public enum ShotLine: String, CaseIterable, Equatable, Hashable, Sendable {
    /// The origin and target sides are opposite non-centre sides.
    case crossShot
    /// The origin and target sides are the same non-centre side.
    case nearPost
    /// Either side is centre, or the origin has no lateral side (7m).
    case neutral
}

/// Pure derivation over `ShotOrigin` and `GoalTarget`: never stores
/// anything, matching `CourtGeometry`. Grouped as a namespace (an
/// uninstantiable enum) because every operation is a function of its
/// arguments alone, with no state of its own.
public enum ShotClassification {}

extension ShotClassification {
    /// The lateral side of a shot's origin, derived from its court sector:
    /// left wing and left back are `.left`, centre is `.center`, right back
    /// and right wing are `.right`. A 7m throw always starts from the same
    /// spot, so it has no lateral side.
    public static func originSide(_ origin: ShotOrigin) -> ShotSide? {
        switch origin {
        case .zone(let zone):
            switch zone.sector {
            case .leftWing, .leftBack: return .left
            case .center: return .center
            case .rightBack, .rightWing: return .right
            }
        case .sevenMeters:
            return nil
        }
    }

    /// The lateral side of a goal target, from the shooter's perspective.
    /// Defined for every case:
    ///   - `.inside`: from its column.
    ///   - `.post`: a post segment takes its post's side; a crossbar
    ///     segment takes its own column.
    ///   - `.out`: wide left/right take their side; `.over` is `.center`.
    public static func targetSide(_ target: GoalTarget) -> ShotSide {
        switch target {
        case .inside(let zone):
            switch zone.column {
            case .left: return .left
            case .center: return .center
            case .right: return .right
            }
        case .post(let segment):
            switch segment {
            case .leftPostTop, .leftPostMiddle, .leftPostBottom, .crossbarLeft: return .left
            case .crossbarCenter: return .center
            case .crossbarRight, .rightPostTop, .rightPostMiddle, .rightPostBottom: return .right
            }
        case .out(let direction):
            switch direction {
            case .wideLeft: return .left
            case .wideRight: return .right
            case .over: return .center
            }
        }
    }

    /// The height band of a goal target, defined only where the vertical
    /// position inside the goal frame is actually known:
    ///   - `.inside`: from its row.
    ///   - `.post`: a post segment takes its own top/middle/bottom; a
    ///     crossbar segment is `.top`.
    ///   - `.out`: never has a height, including `.over`.
    public static func targetHeight(_ target: GoalTarget) -> ShotHeight? {
        switch target {
        case .inside(let zone):
            switch zone.row {
            case .top: return .top
            case .middle: return .middle
            case .bottom: return .bottom
            }
        case .post(let segment):
            switch segment {
            case .leftPostTop, .rightPostTop, .crossbarLeft, .crossbarCenter, .crossbarRight: return .top
            case .leftPostMiddle, .rightPostMiddle: return .middle
            case .leftPostBottom, .rightPostBottom: return .bottom
            }
        case .out:
            return nil
        }
    }

    /// Classifies the shot line between an origin and a target:
    ///   - `.crossShot` when the origin and target sides are opposite
    ///     non-centre sides.
    ///   - `.nearPost` when the origin and target sides are the same
    ///     non-centre side.
    ///   - `.neutral` otherwise (either side is centre, or the origin has
    ///     no lateral side).
    public static func line(from origin: ShotOrigin, to target: GoalTarget) -> ShotLine {
        guard let originSide = originSide(origin) else { return .neutral }
        let targetSide = targetSide(target)

        switch (originSide, targetSide) {
        case (.center, _), (_, .center):
            return .neutral
        case (.left, .left), (.right, .right):
            return .nearPost
        case (.left, .right), (.right, .left):
            return .crossShot
        }
    }
}

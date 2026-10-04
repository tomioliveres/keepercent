// ShotDirections summarises where shots from each origin go: the side of
// the goal most of them were aimed at, and how well that worked (T6.8).
// The court view draws it as one arrow per origin, from the zone towards
// `CourtGeometry.goalPoint(for:)`.
//
// Perspective: the SHOOTER's, like every side in this package. The court is
// drawn with the goal at the top and the shooter's left touchline on screen
// left (`CourtPoint.x == 0`), and the goal mouth runs from the shooter's
// left post to the right post, so a target's `ShotSide` maps straight onto
// the drawing's left/right without any mirroring.

/// The side most shots from one origin were aimed at.
public struct ShotDirection: Equatable, Sendable {
    /// Where the shots came from.
    public let origin: ShotOrigin
    /// The side of the goal most of them went to.
    public let side: ShotSide
    /// Shots to `side` over every shot from `origin`: the "4/6" share.
    public let shots: Tally
    /// How the shots to `side` ended, for the active reading: goals over
    /// those shots (shooter) or saves over those on target (goalkeeper).
    public let conversion: Tally

    public init(origin: ShotOrigin, side: ShotSide, shots: Tally, conversion: Tally) {
        self.origin = origin
        self.side = side
        self.shots = shots
        self.conversion = conversion
    }
}

extension StatsEngine {
    /// The minimum number of shots an origin needs before it gets an
    /// arrow: one shot is a dot, not a direction.
    public static let minimumShotsForDirection = 2

    /// One `ShotDirection` per origin with at least
    /// `minimumShotsForDirection` shots, in `ShotOrigin.allCases` order
    /// (the 7 m mark last).
    ///
    /// Every shot has a side (`ShotClassification.targetSide` is total), so
    /// misses count: a wide-left miss was still aimed left, and an over
    /// miss counts as centre, exactly as `lineDistribution` counts them.
    /// A tie picks the centre first, then the cross-court side, then the
    /// near post; an origin with no lateral side (centre, 7 m) picks left
    /// before right. The conversion uses the same definitions as the rest
    /// of the app: `effectiveness` and `saveRate` over the winning side's
    /// shots.
    public func dominantDirections(_ reading: StatsReading) -> [ShotDirection] {
        ShotOrigin.allCases.compactMap { origin in
            let fromOrigin = shots(from: origin)
            let total = fromOrigin.shots.count
            guard total >= Self.minimumShotsForDirection else { return nil }

            let sides = Self.tieBreakOrder(for: origin)
            let counts = sides.map { side in
                fromOrigin.shots.filter { ShotClassification.targetSide($0.target) == side }.count
            }
            guard let best = counts.max(), let index = counts.firstIndex(of: best) else { return nil }
            let side = sides[index]

            let toSide = StatsEngine(shots: fromOrigin.shots.filter {
                ShotClassification.targetSide($0.target) == side
            })
            let conversion = reading == .effectiveness ? toSide.effectiveness : toSide.saveRate
            return ShotDirection(
                origin: origin,
                side: side,
                shots: Tally(successes: best, attempts: total),
                conversion: conversion
            )
        }
    }

    /// The sides in the order a tie is broken: centre, then cross-court,
    /// then near post. `firstIndex(of:)` over this order keeps the first.
    private static func tieBreakOrder(for origin: ShotOrigin) -> [ShotSide] {
        switch ShotClassification.originSide(origin) {
        case .left: return [.center, .right, .left]
        case .right: return [.center, .left, .right]
        case .center, nil: return [.center, .left, .right]
        }
    }
}

extension CourtGeometry {
    /// The point on the goal mouth an arrow towards `side` ends at: the
    /// centre of that third of the mouth, on the goal line.
    public func goalPoint(for side: ShotSide) -> CourtPoint {
        let mouth = goalMouth
        let third = (mouth.to.x - mouth.from.x) / 3
        let index: Double
        switch side {
        case .left: index = 0
        case .center: index = 1
        case .right: index = 2
        }
        return CourtPoint(x: mouth.from.x + third * (index + 0.5), y: mouth.from.y)
    }
}

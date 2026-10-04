import Foundation
import Testing
@testable import KeepercentDomain

private let referenceDate = Date(timeIntervalSince1970: 0)

private func point(xMeters: Double, yMeters: Double) -> CourtPoint {
    let geometry = CourtGeometry.standard
    return CourtPoint(x: xMeters / geometry.widthInMeters + 0.5, y: yMeters / geometry.depthInMeters)
}

private let leftWingNear = point(xMeters: -8, yMeters: 3)
private let rightWingNear = point(xMeters: 8, yMeters: 3)
private let centerFar = point(xMeters: 0, yMeters: 11)

private let leftWing = ShotOrigin.zone(CourtZone(sector: .leftWing, depth: .near))
private let rightWing = ShotOrigin.zone(CourtZone(sector: .rightWing, depth: .near))
private let center = ShotOrigin.zone(CourtZone(sector: .center, depth: .far))

private func shot(
    from originPoint: CourtPoint? = nil,
    isSevenMeters: Bool = false,
    to column: GoalColumn,
    outcome: ShotOutcome = .goal
) -> Shot {
    Shot(
        attackingSide: .rival,
        originPoint: originPoint,
        isSevenMeters: isSevenMeters,
        target: .inside(GoalZone(row: .middle, column: column)),
        outcome: outcome,
        date: referenceDate
    )
}

private func miss(from originPoint: CourtPoint, _ direction: MissDirection) -> Shot {
    Shot(
        attackingSide: .rival,
        originPoint: originPoint,
        target: .out(direction, nil),
        outcome: .out,
        date: referenceDate
    )
}

@Suite("StatsEngine.dominantDirections")
struct DominantDirectionsTests {
    @Test("Picks the side most shots from an origin went to, with its share")
    func dominantSide() {
        let engine = StatsEngine(shots: [
            shot(from: leftWingNear, to: .right),
            shot(from: leftWingNear, to: .right, outcome: .saved),
            shot(from: leftWingNear, to: .right),
            shot(from: leftWingNear, to: .left),
        ])

        let directions = engine.dominantDirections(.effectiveness)

        #expect(directions == [
            ShotDirection(
                origin: leftWing,
                side: .right,
                shots: Tally(successes: 3, attempts: 4),
                conversion: Tally(successes: 2, attempts: 3)
            ),
        ])
    }

    @Test("An origin needs at least two shots")
    func minimumSample() {
        let engine = StatsEngine(shots: [
            shot(from: leftWingNear, to: .right),
            shot(from: rightWingNear, to: .left),
            shot(from: rightWingNear, to: .left),
        ])

        let origins = engine.dominantDirections(.effectiveness).map(\.origin)

        #expect(origins == [rightWing])
    }

    @Test("Shots without an origin are ignored")
    func noOrigin() {
        let engine = StatsEngine(shots: [
            shot(to: .left),
            shot(to: .left),
        ])

        #expect(engine.dominantDirections(.effectiveness).isEmpty)
    }

    @Test("Misses with a side count towards the share and as failed attempts")
    func missesCount() {
        let engine = StatsEngine(shots: [
            miss(from: rightWingNear, .wideLeft),
            miss(from: rightWingNear, .wideLeft),
            shot(from: rightWingNear, to: .left),
            shot(from: rightWingNear, to: .right),
        ])

        let direction = engine.dominantDirections(.effectiveness).first

        #expect(direction?.side == .left)
        #expect(direction?.shots == Tally(successes: 3, attempts: 4))
        #expect(direction?.conversion == Tally(successes: 1, attempts: 3))
    }

    @Test("The goalkeeper reading converts saves over shots on target to that side")
    func saveRateReading() {
        let engine = StatsEngine(shots: [
            shot(from: leftWingNear, to: .right, outcome: .saved),
            shot(from: leftWingNear, to: .right, outcome: .goal),
            shot(from: leftWingNear, to: .right, outcome: .post),
            miss(from: leftWingNear, .wideRight),
        ])

        let direction = engine.dominantDirections(.saveRate).first

        #expect(direction?.shots == Tally(successes: 4, attempts: 4))
        #expect(direction?.conversion == Tally(successes: 1, attempts: 2))
    }

    @Test("A tie prefers the centre")
    func tieBreaksOnCentre() {
        let engine = StatsEngine(shots: [
            shot(from: leftWingNear, to: .right),
            shot(from: leftWingNear, to: .center),
        ])

        #expect(engine.dominantDirections(.effectiveness).first?.side == .center)
    }

    @Test("A tie without the centre prefers the cross-court side")
    func tieBreaksOnCrossCourt() {
        let fromLeft = StatsEngine(shots: [
            shot(from: leftWingNear, to: .left),
            shot(from: leftWingNear, to: .right),
        ])
        let fromRight = StatsEngine(shots: [
            shot(from: rightWingNear, to: .right),
            shot(from: rightWingNear, to: .left),
        ])

        #expect(fromLeft.dominantDirections(.effectiveness).first?.side == .right)
        #expect(fromRight.dominantDirections(.effectiveness).first?.side == .left)
    }

    @Test("A tie from an origin with no lateral side prefers the left")
    func tieBreaksOnLeftForCentralOrigins() {
        let engine = StatsEngine(shots: [
            shot(from: centerFar, to: .right),
            shot(from: centerFar, to: .left),
            shot(isSevenMeters: true, to: .right),
            shot(isSevenMeters: true, to: .left),
        ])

        let directions = engine.dominantDirections(.effectiveness)

        #expect(directions.map(\.origin) == [center, .sevenMeters])
        #expect(directions.map(\.side) == [.left, .left])
    }

    @Test("Entries follow ShotOrigin.allCases, with the 7 m mark last")
    func order() {
        let engine = StatsEngine(shots: [
            shot(isSevenMeters: true, to: .left),
            shot(isSevenMeters: true, to: .left),
            shot(from: rightWingNear, to: .left),
            shot(from: rightWingNear, to: .left),
            shot(from: leftWingNear, to: .right),
            shot(from: leftWingNear, to: .right),
        ])

        let origins = engine.dominantDirections(.effectiveness).map(\.origin)

        #expect(origins == [leftWing, rightWing, .sevenMeters])
    }
}

@Suite("CourtGeometry.goalPoint(for:)")
struct GoalPointTests {
    let geometry = CourtGeometry.standard

    @Test("Every side's point lies on the goal mouth")
    func onGoalMouth() {
        let mouth = geometry.goalMouth
        for side in ShotSide.allCases {
            let goalPoint = geometry.goalPoint(for: side)
            #expect(goalPoint.y == mouth.from.y)
            #expect(goalPoint.x > mouth.from.x)
            #expect(goalPoint.x < mouth.to.x)
        }
    }

    @Test("Points sit at the centre of each third, ordered left to right")
    func thirds() {
        let mouth = geometry.goalMouth
        let third = (mouth.to.x - mouth.from.x) / 3

        #expect(abs(geometry.goalPoint(for: .left).x - (mouth.from.x + third / 2)) < 1e-12)
        #expect(geometry.goalPoint(for: .center).x == 0.5)
        #expect(abs(geometry.goalPoint(for: .right).x - (mouth.to.x - third / 2)) < 1e-12)
        #expect(geometry.goalPoint(for: .left).x < geometry.goalPoint(for: .center).x)
        #expect(geometry.goalPoint(for: .center).x < geometry.goalPoint(for: .right).x)
    }
}

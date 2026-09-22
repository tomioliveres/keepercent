import Foundation
import Testing
@testable import KeepercentDomain

private let referenceDate = Date(timeIntervalSince1970: 0)

/// Builds a normalized point directly from a metric offset from the goal
/// centre, matching the helper in CourtGeometryTests.swift and
/// ShotTests.swift, so this file states intent (metres from the goal)
/// rather than a raw normalized number.
private func point(xMeters: Double, yMeters: Double, geometry: CourtGeometry = .standard) -> CourtPoint {
    CourtPoint(x: xMeters / geometry.widthInMeters + 0.5, y: yMeters / geometry.depthInMeters)
}

/// A point resolving to `CourtZone(sector: .leftBack, depth: .near)`, per
/// `CourtGeometryTests.swift`'s own fixture for that zone.
private let leftBackNearPoint = point(xMeters: -5.0, yMeters: 8.0)

@Suite("ShotSummary — the last-shot card's text, per docs/mvp.md §6")
struct ShotSummaryTests {

    @Test("A rival shot reads shooter · origin zone · target · outcome, matching docs/mvp.md's own example")
    func rivalShotMatchesDocumentedExample() {
        let shot = Shot(
            attackingSide: .rival,
            shooter: Player(number: 7),
            originPoint: leftBackNearPoint,
            target: .post(.crossbarCenter),
            outcome: .post,
            date: referenceDate
        )
        let summary = ShotSummary(shot: shot)
        #expect(summary.subject == "#7")
        #expect(summary.origin == "left back")
        #expect(summary.target == "crossbar center")
        #expect(summary.outcome == "POST")
        #expect(summary.text == "#7 · left back · crossbar center · POST")
    }

    @Test("A 7m shot reads '7 m' as its origin, regardless of any stray origin point")
    func sevenMetersReadsAsItsOwnOrigin() {
        let shot = Shot(
            attackingSide: .rival,
            shooter: Player(number: 4),
            isSevenMeters: true,
            target: .inside(GoalZone(row: .middle, column: .center)),
            outcome: .goal,
            date: referenceDate
        )
        let summary = ShotSummary(shot: shot)
        #expect(summary.origin == "7 m")
    }

    @Test("An own-team shot reads the active rival goalkeeper as 'vs #<number>', never a shooter")
    func ownShotReadsAsVersusTheGoalkeeper() {
        let shot = Shot(
            attackingSide: .own,
            facingGoalkeeper: Player(number: 12, isGoalkeeper: true),
            originPoint: leftBackNearPoint,
            target: .out(.wideLeft),
            outcome: .out,
            date: referenceDate
        )
        let summary = ShotSummary(shot: shot)
        #expect(summary.subject == "vs #12")
    }

    @Test("An inside target reads as its row and column, e.g. 'top left'")
    func insideTargetReadsAsRowAndColumn() {
        let shot = Shot(
            attackingSide: .rival,
            shooter: Player(number: 9),
            originPoint: leftBackNearPoint,
            target: .inside(GoalZone(row: .top, column: .left)),
            outcome: .goal,
            date: referenceDate
        )
        let summary = ShotSummary(shot: shot)
        #expect(summary.target == "top left")
    }

    @Test("An out target reads as its direction, e.g. 'wide right'")
    func outTargetReadsAsItsDirection() {
        let shot = Shot(
            attackingSide: .rival,
            shooter: Player(number: 9),
            originPoint: leftBackNearPoint,
            target: .out(.wideRight),
            outcome: .out,
            date: referenceDate
        )
        let summary = ShotSummary(shot: shot)
        #expect(summary.target == "wide right")
    }

    @Test("A shot missing its shooter (a corrupt or decoded-away row) reads as a placeholder subject")
    func missingShooterReadsAsPlaceholder() {
        let shot = Shot(
            attackingSide: .rival,
            shooter: nil,
            originPoint: leftBackNearPoint,
            target: .out(.over),
            outcome: .out,
            date: referenceDate
        )
        let summary = ShotSummary(shot: shot)
        #expect(summary.subject == "—")
    }

    @Test("A shot with neither an origin point nor a 7m flag (a corrupt row) reads as a placeholder origin")
    func missingOriginReadsAsPlaceholder() {
        let shot = Shot(
            attackingSide: .rival,
            shooter: Player(number: 9),
            originPoint: nil,
            isSevenMeters: false,
            target: .out(.over),
            outcome: .out,
            date: referenceDate
        )
        let summary = ShotSummary(shot: shot)
        #expect(summary.origin == "—")
    }
}

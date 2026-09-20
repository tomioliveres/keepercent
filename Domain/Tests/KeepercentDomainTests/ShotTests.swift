import Foundation
import Testing
@testable import KeepercentDomain

/// Builds a normalized point directly from a metric offset from the goal
/// centre, matching the helper in CourtGeometryTests.swift, so shot origin
/// tests state intent (metres from the goal) rather than normalized magic
/// numbers.
private func point(xMeters: Double, yMeters: Double, geometry: CourtGeometry = .standard) -> CourtPoint {
    CourtPoint(x: xMeters / geometry.widthInMeters + 0.5, y: yMeters / geometry.depthInMeters)
}

private let referenceDate = Date(timeIntervalSince1970: 0)

/// Builds a `Shot` with sensible defaults, so each test only states the
/// fields it actually cares about.
private func shot(
    originPoint: CourtPoint? = nil,
    isSevenMeters: Bool = false,
    target: GoalTarget = .inside(GoalZone(row: .middle, column: .center))
) -> Shot {
    Shot(
        attackingSide: .rival,
        originPoint: originPoint,
        isSevenMeters: isSevenMeters,
        target: target,
        outcome: .goal,
        date: referenceDate
    )
}

@Suite("Handedness raw value round-trip")
struct HandednessRawValueTests {

    @Test("Every case round-trips through its raw value", arguments: Handedness.allCases)
    func rawValueRoundTrips(value: Handedness) {
        #expect(Handedness(rawValue: value.rawValue) == value)
    }

    @Test("An unknown raw value returns nil")
    func unknownRawValueReturnsNil() {
        #expect(Handedness(rawValue: "unknown") == nil)
    }
}

@Suite("SessionKind raw value round-trip")
struct SessionKindRawValueTests {

    @Test("Every case round-trips through its raw value", arguments: SessionKind.allCases)
    func rawValueRoundTrips(value: SessionKind) {
        #expect(SessionKind(rawValue: value.rawValue) == value)
    }

    @Test("An unknown raw value returns nil")
    func unknownRawValueReturnsNil() {
        #expect(SessionKind(rawValue: "unknown") == nil)
    }
}

@Suite("AttackingSide raw value round-trip")
struct AttackingSideRawValueTests {

    @Test("Every case round-trips through its raw value", arguments: AttackingSide.allCases)
    func rawValueRoundTrips(value: AttackingSide) {
        #expect(AttackingSide(rawValue: value.rawValue) == value)
    }

    @Test("An unknown raw value returns nil")
    func unknownRawValueReturnsNil() {
        #expect(AttackingSide(rawValue: "unknown") == nil)
    }
}

@Suite("ShotDelivery raw value round-trip")
struct ShotDeliveryRawValueTests {

    @Test("Every case round-trips through its raw value", arguments: ShotDelivery.allCases)
    func rawValueRoundTrips(value: ShotDelivery) {
        #expect(ShotDelivery(rawValue: value.rawValue) == value)
    }

    @Test("An unknown raw value returns nil")
    func unknownRawValueReturnsNil() {
        #expect(ShotDelivery(rawValue: "unknown") == nil)
    }
}

@Suite("ShotApproach raw value round-trip")
struct ShotApproachRawValueTests {

    @Test("Every case round-trips through its raw value", arguments: ShotApproach.allCases)
    func rawValueRoundTrips(value: ShotApproach) {
        #expect(ShotApproach(rawValue: value.rawValue) == value)
    }

    @Test("An unknown raw value returns nil")
    func unknownRawValueReturnsNil() {
        #expect(ShotApproach(rawValue: "unknown") == nil)
    }
}

@Suite("Shot.origin")
struct ShotOriginDerivationTests {

    @Test("A 7m shot always derives .sevenMeters, regardless of originPoint")
    func sevenMetersWinsOverOriginPoint() {
        let withPoint = shot(originPoint: point(xMeters: -8, yMeters: 3), isSevenMeters: true)
        #expect(withPoint.origin == .sevenMeters)

        let withoutPoint = shot(originPoint: nil, isSevenMeters: true)
        #expect(withoutPoint.origin == .sevenMeters)
    }

    @Test("A 7m shot stores no originPoint, so persistence cannot read a phantom one")
    func sevenMetersDropsTheOriginPoint() {
        let recorded = shot(originPoint: point(xMeters: -8, yMeters: 3), isSevenMeters: true)
        #expect(recorded.originPoint == nil)
    }

    @Test(
        "A non-7m shot derives the zone CourtGeometry would derive from the same point",
        arguments: [
            (xMeters: -8.0, yMeters: 3.0, zone: CourtZone(sector: .leftWing, depth: .near)),
            (xMeters: 0.0, yMeters: 6.0, zone: CourtZone(sector: .center, depth: .near)),
            (xMeters: 5.0, yMeters: 8.0, zone: CourtZone(sector: .rightBack, depth: .near))
        ]
    )
    func derivesExpectedZone(input: (xMeters: Double, yMeters: Double, zone: CourtZone)) {
        let origin = point(xMeters: input.xMeters, yMeters: input.yMeters)
        let recorded = shot(originPoint: origin)
        #expect(recorded.origin == .zone(input.zone))
    }

    @Test("Neither 7m nor an originPoint means no origin")
    func noOriginWhenNeitherIsSet() {
        let recorded = shot(originPoint: nil, isSevenMeters: false)
        #expect(recorded.origin == nil)
    }
}

@Suite("Shot.line")
struct ShotClassificationDerivationTests {

    @Test("A left-side origin with a right-side target is a cross-shot")
    func crossShot() {
        let origin = point(xMeters: -8, yMeters: 3)
        let target = GoalTarget.inside(GoalZone(row: .middle, column: .right))
        let recorded = shot(originPoint: origin, target: target)
        #expect(recorded.line == .crossShot)
    }

    @Test("A left-side origin with a left-side target is near-post")
    func nearPost() {
        let origin = point(xMeters: -8, yMeters: 3)
        let target = GoalTarget.inside(GoalZone(row: .middle, column: .left))
        let recorded = shot(originPoint: origin, target: target)
        #expect(recorded.line == .nearPost)
    }

    @Test("A centre origin is always neutral")
    func neutral() {
        let origin = point(xMeters: 0, yMeters: 6)
        let target = GoalTarget.inside(GoalZone(row: .middle, column: .right))
        let recorded = shot(originPoint: origin, target: target)
        #expect(recorded.line == .neutral)
    }

    @Test("line is nil when origin is nil")
    func nilWhenOriginIsNil() {
        let recorded = shot(originPoint: nil, isSevenMeters: false)
        #expect(recorded.line == nil)
    }

    @Test(
        "A 7 m throw is neutral whatever it aims at",
        arguments: [GoalColumn.left, .center, .right]
    )
    func sevenMetersIsAlwaysNeutral(column: GoalColumn) {
        let target = GoalTarget.inside(GoalZone(row: .middle, column: column))
        let recorded = shot(isSevenMeters: true, target: target)
        #expect(recorded.line == .neutral)
    }
}

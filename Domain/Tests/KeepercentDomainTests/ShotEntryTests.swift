import Foundation
import Testing
@testable import KeepercentDomain

private let referenceDate = Date(timeIntervalSince1970: 0)
private let anyPoint = CourtPoint(x: 0.5, y: 0.3)
private let rivalShooter = Player(number: 7)
private let rivalGoalkeeper = Player(number: 12, isGoalkeeper: true)

/// Builds `Shot.record` arguments with sensible defaults, so each test only
/// states the fields it actually cares about.
private func record(
    attackingSide: AttackingSide = .rival,
    shooter: Player? = rivalShooter,
    activeRivalGoalkeeper: Player? = nil,
    originPoint: CourtPoint? = anyPoint,
    isSevenMeters: Bool = false,
    target: GoalTarget = .inside(GoalZone(row: .middle, column: .center)),
    outcome: ShotOutcome? = .goal,
    delivery: ShotDelivery? = nil,
    approach: ShotApproach? = nil,
    date: Date = referenceDate
) throws -> Shot {
    try Shot.record(
        attackingSide: attackingSide,
        shooter: shooter,
        activeRivalGoalkeeper: activeRivalGoalkeeper,
        originPoint: originPoint,
        isSevenMeters: isSevenMeters,
        target: target,
        outcome: outcome,
        delivery: delivery,
        approach: approach,
        date: date
    )
}

@Suite("Shot.record — rival attacks require a shooter")
struct ShotRecordRivalShooterTests {

    @Test("A rival attack without a shooter is rejected")
    func missingShooterIsRejected() {
        #expect(throws: ShotEntryError.missingShooter) {
            try record(attackingSide: .rival, shooter: nil)
        }
    }

    @Test("A rival attack keeps the shooter and drops any active rival goalkeeper")
    func rivalAttackDropsFacingGoalkeeper() throws {
        let shot = try record(attackingSide: .rival, shooter: rivalShooter, activeRivalGoalkeeper: rivalGoalkeeper)
        #expect(shot.shooter == rivalShooter)
        #expect(shot.facingGoalkeeper == nil)
    }
}

@Suite("Shot.record — own-team attacks require the active rival goalkeeper")
struct ShotRecordOwnGoalkeeperTests {

    @Test("An own-team attack without an active rival goalkeeper is rejected")
    func missingRivalGoalkeeperIsRejected() {
        #expect(throws: ShotEntryError.missingRivalGoalkeeper) {
            try record(attackingSide: .own, shooter: nil, activeRivalGoalkeeper: nil)
        }
    }

    @Test("An own-team attack records the active rival goalkeeper and drops any shooter")
    func ownAttackDropsShooter() throws {
        let shot = try record(attackingSide: .own, shooter: rivalShooter, activeRivalGoalkeeper: rivalGoalkeeper)
        #expect(shot.facingGoalkeeper == rivalGoalkeeper)
        #expect(shot.shooter == nil)
    }
}

@Suite("Shot.record — origin is required unless it is a 7 m throw")
struct ShotRecordOriginTests {

    @Test("A non-7m shot without an origin point is rejected")
    func missingOriginIsRejected() {
        #expect(throws: ShotEntryError.missingOrigin) {
            try record(originPoint: nil, isSevenMeters: false)
        }
    }

    @Test("A 7m shot needs no origin point")
    func sevenMetersNeedsNoOrigin() throws {
        let shot = try record(originPoint: nil, isSevenMeters: true, target: .out(.over), outcome: nil)
        #expect(shot.isSevenMeters)
        #expect(shot.originPoint == nil)
    }
}

@Suite("Shot.record — outcome must agree with the target")
struct ShotRecordOutcomeTests {

    @Test("A post target with no outcome auto-resolves to .post")
    func postTargetImpliesOutcome() throws {
        let shot = try record(target: .post(.crossbarCenter), outcome: nil)
        #expect(shot.outcome == .post)
    }

    @Test("An out target with no outcome auto-resolves to .out")
    func outTargetImpliesOutcome() throws {
        let shot = try record(target: .out(.wideLeft), outcome: nil)
        #expect(shot.outcome == .out)
    }

    @Test("A post target with a contradicting outcome is rejected")
    func postTargetRejectsContradictingOutcome() {
        #expect(throws: ShotEntryError.outcomeContradictsTarget) {
            try record(target: .post(.crossbarCenter), outcome: .goal)
        }
    }

    @Test("An inside target with no outcome is rejected")
    func insideTargetRequiresOutcome() {
        #expect(throws: ShotEntryError.missingOutcome) {
            try record(target: .inside(GoalZone(row: .top, column: .left)), outcome: nil)
        }
    }

    @Test("An inside target accepts .goal")
    func insideTargetAcceptsGoal() throws {
        let shot = try record(target: .inside(GoalZone(row: .top, column: .left)), outcome: .goal)
        #expect(shot.outcome == .goal)
    }

    @Test("An inside target accepts .saved")
    func insideTargetAcceptsSaved() throws {
        let shot = try record(target: .inside(GoalZone(row: .top, column: .left)), outcome: .saved)
        #expect(shot.outcome == .saved)
    }

    @Test("An inside target rejects .post as an outcome")
    func insideTargetRejectsPostOutcome() {
        #expect(throws: ShotEntryError.outcomeContradictsTarget) {
            try record(target: .inside(GoalZone(row: .top, column: .left)), outcome: .post)
        }
    }

    @Test("An inside target rejects .out as an outcome")
    func insideTargetRejectsOutOutcome() {
        #expect(throws: ShotEntryError.outcomeContradictsTarget) {
            try record(target: .inside(GoalZone(row: .top, column: .left)), outcome: .out)
        }
    }
}

/// The UI shows exactly one rejection reason per attempt, in the order the
/// entry flow itself asks the questions: who (shooter / active rival
/// goalkeeper) -> where from (origin) -> where to / how it ended (outcome).
/// When several rules are broken at once, the earliest one in that order is
/// the one the caller sees.
@Suite("Shot.record — guard order when several rules are broken at once")
struct ShotRecordGuardOrderTests {

    @Test("A rival attack with no shooter, no origin and no outcome reports the missing shooter first")
    func shooterBeforeOriginBeforeOutcome() {
        #expect(throws: ShotEntryError.missingShooter) {
            try record(
                attackingSide: .rival,
                shooter: nil,
                originPoint: nil,
                target: .inside(GoalZone(row: .top, column: .left)),
                outcome: nil
            )
        }
    }

    @Test("An own attack with no active rival goalkeeper, no origin and no outcome reports the missing goalkeeper first")
    func rivalGoalkeeperBeforeOriginBeforeOutcome() {
        #expect(throws: ShotEntryError.missingRivalGoalkeeper) {
            try record(
                attackingSide: .own,
                shooter: nil,
                activeRivalGoalkeeper: nil,
                originPoint: nil,
                target: .inside(GoalZone(row: .top, column: .left)),
                outcome: nil
            )
        }
    }

    @Test("A missing origin is reported before a missing outcome, once who took the shot is resolved")
    func originBeforeOutcome() {
        #expect(throws: ShotEntryError.missingOrigin) {
            try record(
                originPoint: nil,
                isSevenMeters: false,
                target: .inside(GoalZone(row: .top, column: .left)),
                outcome: nil
            )
        }
    }

    @Test("A missing origin is reported even when the outcome would also contradict the target")
    func originBeforeOutcomeContradiction() {
        #expect(throws: ShotEntryError.missingOrigin) {
            try record(
                originPoint: nil,
                isSevenMeters: false,
                target: .post(.crossbarCenter),
                outcome: .goal
            )
        }
    }
}

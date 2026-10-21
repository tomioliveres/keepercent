import Foundation
import Testing
import KeepercentDomain

struct ShotEntryLegacyRegressionTests {
    @Test func boundaryAndReports() throws {
        let person = Player(id: UUID(uuidString: "00000000-0000-0000-0000-000000000007"), number: 7)
        let keeper = Player(id: UUID(uuidString: "00000000-0000-0000-0000-000000000012"), number: 12, isGoalkeeper: true)
        var shots: [Shot] = []
        var rejected = 0
        for side in AttackingSide.allCases {
            for target in GoalTarget.allCases {
                for outcome in [ShotOutcome?.none] + ShotOutcome.allCases.map(Optional.some) {
                    let before = shots
                    let expected = target.impliedOutcome.map { implied in
                        outcome == nil || outcome == implied
                    } ?? (outcome == .goal || outcome == .saved)
                    do {
                        let shot = try Shot.record(attackingSide: side, shooter: person,
                            activeRivalGoalkeeper: keeper, ownShooter: person, ownGoalkeeper: keeper,
                            originPoint: nil, isSevenMeters: true, target: target, outcome: outcome,
                            date: Date(timeIntervalSince1970: 0))
                        #expect(expected)
                        #expect(shot.ownShooter == (side == .own ? person : nil))
                        #expect(shot.ownGoalkeeper == (side == .rival ? keeper : nil))
                        #expect(shot.origin == .sevenMeters)
                        let decoded = Shot(attackingSideCode: side.rawValue, shooter: shot.shooter,
                            facingGoalkeeper: shot.facingGoalkeeper, ownShooter: shot.ownShooter,
                            ownGoalkeeper: shot.ownGoalkeeper, originX: nil, originY: nil,
                            isSevenMeters: true, targetCode: target.code, outcomeCode: shot.outcome.rawValue,
                            deliveryCode: nil, approachCode: nil, date: shot.date)
                        #expect(decoded == shot)
                        #expect(ShotSummary(shot: shot, locale: Locale(identifier: "en")).outcome == shot.outcome.rawValue.uppercased())
                        shots.append(shot)
                    } catch {
                        #expect(!expected)
                        #expect(error == (outcome == nil ? .missingOutcome : .outcomeContradictsTarget))
                        #expect(shots == before)
                        rejected += 1
                    }
                }
            }
        }
        let stats = StatsEngine(shots: shots)
        #expect(shots.count == 108)
        #expect(rejected == 162)
        #expect(stats.sevenMeterShots.shots.count == 108)
        #expect(stats.fieldShots.shots.isEmpty)
        #expect(stats.shots(byOwnShooter: person.id!).shots.count == 54)
        #expect(stats.shots(facingOwnGoalkeeper: keeper.id!).shots.count == 54)
        #expect(stats.shots(by: person.id!).shots.count == 54)
        #expect(stats.shots(facing: keeper.id!).shots.count == 54)
        #expect(stats.outcomeCounts == [.goal: 18, .saved: 18, .post: 36, .out: 36])
    }
}

struct ShotEntryCompletenessMatrixTests {
    @Test func completeStateMatrix() {
        let person = Player(number: 7)
        let keeper = Player(number: 12, isGoalkeeper: true)
        for side in AttackingSide.allCases {
            for target in [GoalTarget?.none] + GoalTarget.allCases.map(Optional.some) {
                for outcome in [ShotOutcome?.none] + ShotOutcome.allCases.map(Optional.some) {
                    for mask in 0..<16 {
                        let shooter = mask & 1 != 0 ? person : nil
                        let rivalKeeper = mask & 2 != 0 ? keeper : nil
                        let point = mask & 4 != 0 ? CourtPoint(x: 0.5, y: 0.3) : nil
                        let seven = mask & 8 != 0
                        let progress = ShotEntryProgress(attackingSide: side, shooter: shooter,
                            activeRivalGoalkeeper: rivalKeeper, originPoint: point,
                            isSevenMeters: seven, target: target, outcome: outcome)
                        let who = side == .rival ? shooter != nil : rivalKeeper != nil
                        let resolved = target?.impliedOutcome ?? ((outcome == .goal || outcome == .saved) ? outcome : nil)
                        let expected = who && (point != nil || seven) && target != nil && resolved != nil
                        #expect(progress.isComplete == expected)
                        if target == nil { #expect(progress.resolvedOutcome == nil) }
                        if expected { #expect(progress.resolvedOutcome == resolved) }
                    }
                }
            }
        }
    }
}

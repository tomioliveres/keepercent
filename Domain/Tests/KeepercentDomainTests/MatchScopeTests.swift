import Foundation
import Testing
@testable import KeepercentDomain

struct MatchScopeTests {
    @Test func ownShooterHistoryPartitionsAcrossOpponentsWithoutNumberJoins() {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000301")!
        let first = UUID()
        let second = UUID()
        let target = GoalTarget.inside(GoalZone(row: .middle, column: .center))
        let old = Player(id: id, number: 7, name: "Original", handedness: .left)
        let renamed = Player(id: id, number: 19, name: "Renamed", isGoalkeeper: true)
        let goal = Shot(attackingSide: .own, ownShooter: old, target: target, outcome: .goal, date: .distantPast)
        let penalty = Shot(attackingSide: .own, ownShooter: renamed, isSevenMeters: true,
                           target: target, outcome: .saved, date: .distantPast)
        let replacement = Shot(attackingSide: .own, ownShooter: Player(id: UUID(), number: 7),
                               target: target, outcome: .goal, date: .distantPast)
        let unknown = Shot(attackingSide: .own, target: target, outcome: .goal, date: .distantPast)
        let matches = [MatchShots(id: first, shots: [goal]),
                       MatchShots(id: second, shots: [penalty, replacement, unknown])]
        func scoped(_ scope: MatchScope) -> StatsEngine {
            StatsEngine(shots: scope.shots(in: matches)).shots(byOwnShooter: id)
        }
        #expect(scoped(.all).shots == [goal, penalty])
        #expect(scoped(.match(first)).shots.first?.ownShooter == old)
        #expect(scoped(.match(second)).shots.first?.ownShooter == renamed)
        #expect(scoped(.all).fieldShots.effectiveness == Tally(successes: 1, attempts: 1))
        #expect(scoped(.all).sevenMeterShots.effectiveness == Tally(successes: 0, attempts: 1))
        #expect(scoped(.match(first)).effectiveness.attempts + scoped(.match(second)).effectiveness.attempts
                == scoped(.all).effectiveness.attempts)
        #expect(scoped(.match(UUID())).shots.isEmpty)
        #expect(goal.ownShooter == old)
    }

    @Test func specificMatchDoesNotLeakOtherMatchesWithIdenticalShotDates() {
        let first = UUID()
        let second = UUID()
        let target = GoalTarget.inside(GoalZone(row: .top, column: .left))
        let goal = Shot(attackingSide: .rival, target: target, outcome: .goal, date: .distantPast)
        let save = Shot(attackingSide: .rival, target: target, outcome: .saved, date: .distantPast)
        let matches = [MatchShots(id: first, shots: [goal]), MatchShots(id: second, shots: [save])]
        #expect(MatchScope.match(first).shots(in: matches) == [goal])
        #expect(MatchScope.match(second).shots(in: matches) == [save])
        #expect(MatchScope.all.shots(in: matches).count == 2)
    }

    @Test func scopedSaveRateRetainsOnTargetDenominatorAndSeparateSevenMeters() {
        let id = UUID()
        let target = GoalTarget.inside(GoalZone(row: .top, column: .left))
        let field = Shot(attackingSide: .own, target: target, outcome: .saved, date: .distantPast)
        let post = Shot(attackingSide: .own, target: .post(.crossbarCenter), outcome: .post, date: .distantPast)
        let seven = Shot(attackingSide: .own, isSevenMeters: true, target: target, outcome: .goal, date: .distantPast)
        let other = Shot(attackingSide: .own, target: target, outcome: .goal, date: .distantPast)
        let matches = [MatchShots(id: id, shots: [field, post, seven]), MatchShots(id: UUID(), shots: [other])]
        let engine = StatsEngine(shots: MatchScope.match(id).shots(in: matches))
        #expect(engine.shots.count == 3)
        #expect(engine.fieldShots.saveRate == Tally(successes: 1, attempts: 1))
        #expect(engine.sevenMeterShots.saveRate == Tally(successes: 0, attempts: 1))
        #expect(engine.saveRate == Tally(successes: 1, attempts: 2))
    }
    @Test func allSpecificEmptyAndMissingScopesNeverWiden() {
        let first = UUID()
        let second = UUID()
        let target = GoalTarget.inside(GoalZone(row: .middle, column: .center))
        let field = Shot(attackingSide: .rival, target: target, outcome: .goal, date: .distantPast)
        let seven = Shot(attackingSide: .rival, isSevenMeters: true, target: target, outcome: .saved, date: .distantPast)
        let matches = [MatchShots(id: first, shots: [field, seven]), MatchShots(id: second, shots: [])]
        #expect(MatchScope.all.shots(in: matches).count == 2)
        let scoped = StatsEngine(shots: MatchScope.match(first).shots(in: matches))
        #expect(scoped.effectiveness == Tally(successes: 1, attempts: 2))
        #expect(scoped.fieldShots.effectiveness == Tally(successes: 1, attempts: 1))
        #expect(scoped.sevenMeterShots.effectiveness == Tally(successes: 0, attempts: 1))
        #expect(MatchScope.match(second).shots(in: matches).isEmpty)
        #expect(MatchScope.match(UUID()).shots(in: matches).isEmpty)
        #expect(MatchScope.all.shots(in: []).isEmpty)
    }
}

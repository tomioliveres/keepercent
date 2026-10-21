import Foundation
import Testing
import KeepercentDomain

@Suite("Order-independent shot entry")
struct ShotEntryProgressTests {
    private let inside = GoalTarget.inside(GoalZone(row: .middle, column: .center))

    @Test("Every ordering records only after the final required step")
    func allInsideOrders() throws {
        for order in permutations([0, 1, 2, 3]) {
            var shooter: Player?
            var point: CourtPoint?
            var target: GoalTarget?
            var outcome: ShotOutcome?
            for (index, step) in order.enumerated() {
                switch step {
                case 0: shooter = Player(number: 7)
                case 1: point = CourtPoint(x: 0.5, y: 0.3)
                case 2: target = inside
                default: outcome = .saved
                }
                let progress = ShotEntryProgress(attackingSide: .rival, shooter: shooter,
                    activeRivalGoalkeeper: nil, originPoint: point, target: target, outcome: outcome)
                #expect(progress.isComplete == (index == 3))
                if progress.isComplete {
                    let shot = try Shot.record(attackingSide: .rival, shooter: shooter,
                        activeRivalGoalkeeper: nil, originPoint: point,
                        target: #require(target), outcome: progress.resolvedOutcome,
                        date: Date(timeIntervalSince1970: 0))
                    #expect(shot.outcome == .saved)
                    #expect(shot.shooter == shooter)
                    #expect(shot.originPoint == point)
                }
            }
        }
    }

    @Test("Post and miss wait for shooter and origin in every order",
          arguments: [GoalTarget.post(.crossbarCenter), .out(.wideLeft, .middle)])
    func impliedOrders(target: GoalTarget) {
        for order in permutations([0, 1, 2]) {
            var shooter: Player?
            var point: CourtPoint?
            var selected: GoalTarget?
            for (index, step) in order.enumerated() {
                switch step {
                case 0: shooter = Player(number: 7)
                case 1: point = CourtPoint(x: 0.5, y: 0.3)
                default: selected = target
                }
                let progress = ShotEntryProgress(attackingSide: .rival, shooter: shooter,
                    activeRivalGoalkeeper: nil, originPoint: point, target: selected, outcome: nil)
                #expect(progress.isComplete == (index == 2))
                if selected != nil { #expect(progress.resolvedOutcome == target.impliedOutcome) }
            }
        }
    }

    @Test("Own attack needs rival keeper, not optional own attribution; 7m needs no point")
    func ownRequirements() {
        let missing = ShotEntryProgress(attackingSide: .own, shooter: Player(number: 7),
            activeRivalGoalkeeper: nil, originPoint: nil, isSevenMeters: true,
            target: inside, outcome: .goal)
        #expect(missing.missingSteps == [.rivalGoalkeeper])
        let ready = ShotEntryProgress(attackingSide: .own, shooter: nil,
            activeRivalGoalkeeper: Player(number: 12, isGoalkeeper: true),
            originPoint: nil, isSevenMeters: true, target: inside, outcome: .goal)
        #expect(ready.isComplete)
    }

    @Test("Pending steps are explicit and target changes cannot reuse contradictory outcomes")
    func missingStepsAndContradictions() {
        let empty = ShotEntryProgress(attackingSide: .rival, shooter: nil,
            activeRivalGoalkeeper: nil, originPoint: nil, target: nil, outcome: nil)
        #expect(empty.missingSteps == [.shooter, .origin, .target])
        let pending = ShotEntryProgress(attackingSide: .rival, shooter: Player(number: 7),
            activeRivalGoalkeeper: nil, originPoint: nil, target: inside, outcome: .goal)
        #expect(pending.missingSteps == [.origin])
        let invalid = ShotEntryProgress(attackingSide: .rival, shooter: Player(number: 7),
            activeRivalGoalkeeper: nil, originPoint: CourtPoint(x: 0.5, y: 0.3),
            target: inside, outcome: .post)
        #expect(invalid.missingSteps == [.outcome])
    }

    private func permutations(_ values: [Int]) -> [[Int]] {
        if values.isEmpty { return [[]] }
        return values.flatMap { first in
            permutations(values.filter { $0 != first }).map { [first] + $0 }
        }
    }
}

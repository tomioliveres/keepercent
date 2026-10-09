import Foundation
import Testing
@testable import KeepercentDomain

struct OwnClubStatsTests {
    private let personID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
    private let otherID = UUID(uuidString: "00000000-0000-0000-0000-000000000102")!
    private let target = GoalTarget.inside(GoalZone(row: .middle, column: .center))

    @Test func ownIdentityFiltersDoNotChangeRivalSemanticsOrGuessUnknownPeople() {
        let person = Player(id: personID, number: 7)
        let replacement = Player(id: otherID, number: 7)
        let attack = Shot(attackingSide: .own, facingGoalkeeper: replacement, ownShooter: person,
                          target: target, outcome: .goal, date: .distantPast)
        let defense = Shot(attackingSide: .rival, shooter: replacement, ownGoalkeeper: person,
                           target: target, outcome: .saved, date: .distantPast)
        let other = Shot(attackingSide: .own, ownShooter: replacement, target: target,
                         outcome: .saved, date: .distantPast)
        let unknown = Shot(attackingSide: .own, facingGoalkeeper: person, target: target,
                           outcome: .goal, date: .distantPast)
        let engine = StatsEngine(shots: [attack, defense, other, unknown])
        #expect(engine.shots(byOwnShooter: personID).shots == [attack])
        #expect(engine.shots(facingOwnGoalkeeper: personID).shots == [defense])
        #expect(engine.shots(by: personID).shots.isEmpty)
        #expect(engine.shots(facing: personID).shots == [unknown])
        #expect(engine.shots(by: otherID).shots == [defense])
        #expect(engine.shots(facing: otherID).shots == [attack])
        #expect(unknown.ownShooter == nil)
    }

    @Test func renumberingAndRoleChangesDoNotMergeSameNumberPeopleAcrossMatches() {
        let old = Player(id: personID, number: 7, name: "Original", handedness: .left)
        let current = Player(id: personID, number: 19, name: "Renamed", isGoalkeeper: true)
        let replacement = Player(id: otherID, number: 7)
        let shots = [old, current, replacement].map {
            Shot(attackingSide: .own, ownShooter: $0, target: target, outcome: .goal, date: .distantPast)
        }
        let engine = StatsEngine(shots: shots)
        #expect(engine.shots(byOwnShooter: personID).shots == Array(shots.prefix(2)))
        #expect(engine.shots(byOwnShooter: otherID).shots == [shots[2]])
        #expect(engine.shots(byOwnShooter: personID).shots.first?.ownShooter == old)
        #expect(engine.shots(byOwnShooter: UUID()).effectiveness.rate == nil)
    }

    @Test func ownKeeperScopeKeepsIndependentOnTargetAndPenaltyDenominators() {
        let person = Player(id: personID, number: 1, isGoalkeeper: true)
        func faced(_ outcome: ShotOutcome, seven: Bool = false) -> Shot {
            let destination: GoalTarget = switch outcome {
            case .goal, .saved: target
            case .post: .post(.crossbarCenter)
            case .out: .out(.wideLeft, .middle)
            }
            return Shot(attackingSide: .rival, ownGoalkeeper: person,
                        originPoint: CourtPoint(x: 0.5, y: 0.8), isSevenMeters: seven,
                        target: destination, outcome: outcome, date: .distantPast)
        }
        let first = UUID()
        let empty = UUID()
        let matches = [MatchShots(id: first, shots: [faced(.saved), faced(.post), faced(.out), faced(.goal, seven: true)]),
                       MatchShots(id: UUID(), shots: [faced(.goal)]), MatchShots(id: empty, shots: [])]
        let engine = StatsEngine(shots: MatchScope.match(first).shots(in: matches)).shots(facingOwnGoalkeeper: personID)
        #expect(engine.shots.count == 4)
        #expect(engine.fieldShots.saveRate == Tally(successes: 1, attempts: 1))
        #expect(engine.sevenMeterShots.saveRate == Tally(successes: 0, attempts: 1))
        #expect(engine.saveRate == Tally(successes: 1, attempts: 2))
        #expect(engine.goalEngine(forSelectedOrigin: .sevenMeters).saveRate == engine.sevenMeterShots.saveRate)
        for scope in [MatchScope.match(empty), .match(UUID())] {
            let missing = StatsEngine(shots: scope.shots(in: matches)).shots(facingOwnGoalkeeper: personID)
            #expect(missing.shots.isEmpty)
            #expect(missing.saveRate.rate == nil)
        }
    }

    @Test func ownKeeperHistorySurvivesRenumberingAndKeepsRankingsDeterministic() {
        let original = Player(id: personID, number: 1, name: "Keeper", isGoalkeeper: true)
        let edited = Player(id: personID, number: 12, name: "Renamed", isGoalkeeper: false)
        let replacement = Player(id: otherID, number: 1, isGoalkeeper: true)
        let saved = Shot(attackingSide: .rival, ownGoalkeeper: original, target: target,
                         outcome: .saved, date: .distantPast)
        let conceded = Shot(attackingSide: .rival, ownGoalkeeper: edited, target: target,
                            outcome: .goal, date: .distantPast)
        let other = Shot(attackingSide: .rival, ownGoalkeeper: replacement, target: target,
                        outcome: .goal, date: .distantPast)
        let unknown = Shot(attackingSide: .rival, shooter: original, target: target,
                          outcome: .goal, date: .distantPast)
        let engine = StatsEngine(shots: [saved, conceded, other, unknown]).shots(facingOwnGoalkeeper: personID)
        #expect(engine.shots == [saved, conceded])
        #expect(engine.saveRate == Tally(successes: 1, attempts: 2))
        #expect(engine.strongGoalZones(limit: 3).first?.tally == engine.saveRate)
        #expect(engine.weakGoalZones(limit: 3).first?.tally == Tally(successes: 1, attempts: 2))
        #expect(engine.goalkeeperPatterns() == engine.goalkeeperPatterns())
        #expect(saved.ownGoalkeeper == original)
        #expect(unknown.ownGoalkeeper == nil)
    }
}

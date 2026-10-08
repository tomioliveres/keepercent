import Foundation
import Testing
@testable import KeepercentDomain

struct OwnAttributionTests {
    private let rival = Player(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, number: 7)
    private let own = Player(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, number: 7, name: "Ana")
    private let date = Date(timeIntervalSince1970: 1_700_000_000)

    @Test func recordingKeepsOptionalOwnShooterSeparateFromRequiredRivalKeeper() throws {
        let shot = try Shot.record(attackingSide: .own, shooter: rival, activeRivalGoalkeeper: rival,
                                   ownShooter: own, ownGoalkeeper: own, originPoint: nil, isSevenMeters: true,
                                   target: .inside(GoalZone(row: .middle, column: .center)), outcome: .goal, date: date)
        #expect(shot.shooter == nil)
        #expect(shot.facingGoalkeeper == rival)
        #expect(shot.ownShooter == own)
        #expect(shot.ownGoalkeeper == nil)
    }

    @Test func recordingKeepsOptionalOwnKeeperSeparateFromRequiredRivalShooter() throws {
        let shot = try Shot.record(attackingSide: .rival, shooter: rival, activeRivalGoalkeeper: rival,
                                   ownShooter: own, ownGoalkeeper: own, originPoint: nil, isSevenMeters: true,
                                   target: .inside(GoalZone(row: .middle, column: .center)), outcome: .saved, date: date)
        #expect(shot.shooter == rival)
        #expect(shot.facingGoalkeeper == nil)
        #expect(shot.ownShooter == nil)
        #expect(shot.ownGoalkeeper == own)
    }

    @Test func ownAttributionNeverSatisfiesMandatoryRivalRequirements() {
        #expect(throws: ShotEntryError.missingShooter) {
            try Shot.record(attackingSide: .rival, shooter: nil, activeRivalGoalkeeper: nil,
                            ownGoalkeeper: own, originPoint: nil, isSevenMeters: true,
                            target: .inside(GoalZone(row: .middle, column: .center)), outcome: .goal, date: date)
        }
        #expect(throws: ShotEntryError.missingRivalGoalkeeper) {
            try Shot.record(attackingSide: .own, shooter: nil, activeRivalGoalkeeper: nil,
                            ownShooter: own, originPoint: nil, isSevenMeters: true,
                            target: .inside(GoalZone(row: .middle, column: .center)), outcome: .saved, date: date)
        }
    }

    @Test(arguments: AttackingSide.allCases, ShotOutcome.allCases)
    func optionalOwnAttributionWorksForEveryOutcomeAndSevenMeters(side: AttackingSide, outcome: ShotOutcome) throws {
        let target: GoalTarget = switch outcome {
        case .goal, .saved: .inside(GoalZone(row: .middle, column: .center))
        case .post: .post(.crossbarCenter)
        case .out: .out(.wideRight, .middle)
        }
        for sevenMeters in [false, true] {
            let shot = try Shot.record(attackingSide: side, shooter: rival, activeRivalGoalkeeper: rival,
                                       ownShooter: own, ownGoalkeeper: own,
                                       originPoint: CourtPoint(x: 0.5, y: 0.8), isSevenMeters: sevenMeters,
                                       target: target, outcome: outcome, date: date)
            #expect(shot.outcome == outcome)
            #expect(shot.ownShooter == (side == .own ? own : nil))
            #expect(shot.ownGoalkeeper == (side == .rival ? own : nil))
            #expect(shot.originPoint == (sevenMeters ? nil : CourtPoint(x: 0.5, y: 0.8)))
            let unknown = try Shot.record(attackingSide: side, shooter: rival, activeRivalGoalkeeper: rival,
                                          originPoint: nil, isSevenMeters: true, target: target, outcome: outcome, date: date)
            #expect(unknown.ownShooter == nil && unknown.ownGoalkeeper == nil)
        }
    }

    @Test(arguments: AttackingSide.allCases)
    func decodingKeepsOwnFactsAndDropsWrongSideWithoutGuessing(side: AttackingSide) throws {
        func decode(ownShooter: Player? = nil, ownGoalkeeper: Player? = nil) -> Shot? {
            Shot(attackingSideCode: side.rawValue, shooter: rival, facingGoalkeeper: rival,
                 ownShooter: ownShooter, ownGoalkeeper: ownGoalkeeper,
                 originX: nil, originY: nil, isSevenMeters: true,
                 targetCode: "inside.middle.center", outcomeCode: "goal",
                 deliveryCode: nil, approachCode: nil, date: date)
        }
        let legacy = try #require(decode())
        #expect(legacy.ownShooter == nil && legacy.ownGoalkeeper == nil)
        let attributed = try #require(decode(ownShooter: own, ownGoalkeeper: own))
        #expect(attributed.ownShooter == (side == .own ? own : nil))
        #expect(attributed.ownGoalkeeper == (side == .rival ? own : nil))
        // Rival fields retain their permissive legacy-decoding contract.
        #expect(attributed.shooter == rival && attributed.facingGoalkeeper == rival)
    }

    @Test func summariesExposeOwnFactsWithoutChangingLegacyOutput() {
        let target = GoalTarget.inside(GoalZone(row: .middle, column: .center))
        let attack = Shot(attackingSide: .own, facingGoalkeeper: rival, ownShooter: own,
                          target: target, outcome: .goal, date: date)
        let defense = Shot(attackingSide: .rival, shooter: rival, ownGoalkeeper: own,
                           target: target, outcome: .saved, date: date)
        #expect(ShotSummary(shot: attack, locale: Locale(identifier: "en")).subject == "Own shooter #7 · vs #7")
        #expect(ShotSummary(shot: defense, locale: Locale(identifier: "en")).subject == "#7 · Own goalkeeper #7")
        for locale in [Locale(identifier: "es"), Locale(identifier: "es-419")] {
            #expect(ShotSummary(shot: attack, locale: locale).subject == "Tirador propio #7 · vs. #7")
            #expect(ShotSummary(shot: defense, locale: locale).subject == "#7 · Portero propio #7")
        }
        let legacyAttack = Shot(attackingSide: .own, facingGoalkeeper: rival, target: target, outcome: .goal, date: date)
        let legacyDefense = Shot(attackingSide: .rival, shooter: rival, target: target, outcome: .saved, date: date)
        #expect(ShotSummary(shot: legacyAttack, locale: Locale(identifier: "en")).subject == "vs #7")
        #expect(ShotSummary(shot: legacyDefense, locale: Locale(identifier: "en")).subject == "#7")
    }

    @Test func plainInitializerNormalizesWrongSideOwnInputs() {
        let target = GoalTarget.inside(GoalZone(row: .middle, column: .center))
        let attack = Shot(attackingSide: .own, ownShooter: own, ownGoalkeeper: rival,
                          target: target, outcome: .goal, date: date)
        let defense = Shot(attackingSide: .rival, ownShooter: rival, ownGoalkeeper: own,
                           target: target, outcome: .saved, date: date)
        #expect(attack.ownShooter == own && attack.ownGoalkeeper == nil)
        #expect(defense.ownShooter == nil && defense.ownGoalkeeper == own)
    }

    @Test func separateMatchDraftsRetainOwnNumbersWithoutChangingRivalOrSnapshots() throws {
        let rivalRoster = try MatchRoster(players: [rival])
        var ownDraft = MatchRosterDraft(available: [own], selected: [own])
        let id = try #require(own.id)
        ownDraft.setNumber(47, for: id)
        ownDraft.setIncluded(false, for: id)
        ownDraft.setIncluded(true, for: id)
        let snapshot = try MatchRoster(players: ownDraft.selectedPlayers)
        #expect(snapshot.players.first?.number == 47)
        #expect(rivalRoster.players.first?.number == 7)
        var locked = MatchRosterDraft(available: [own], selected: snapshot.players, lockedIDs: [id])
        locked.setNumber(48, for: id)
        locked.setIncluded(false, for: id)
        #expect(locked.selectedPlayers == snapshot.players)
        let replacement = Player(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, number: 47)
        #expect(throws: RosterError.self) { try MatchRoster(players: snapshot.players + [replacement]) }
        #expect(locked.selectedPlayers == snapshot.players)
        #expect(try MatchRoster(players: []).players.isEmpty)
    }
}

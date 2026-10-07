import Foundation
import Testing
@testable import KeepercentDomain

struct MatchRosterTests {
    @Test func rosterEditPreservesIdentityEvenWithNumberOnlyDraft() throws {
        let id = UUID()
        let original = Player(id: id, number: 7)
        let roster = try Roster(players: [original])
        let edited = try roster.update(number: 7, to: Player(number: 9, name: "Ana"))
        #expect(edited.player(number: 9)?.id == id)
    }

    @Test func renumberingRetainsRepeatAfterGoalPairs() {
        let id = UUID()
        let shots = (0..<5).map { index in
            Shot(attackingSide: .rival, shooter: Player(id: id, number: index + 1),
                 originPoint: CourtPoint(x: 0.5, y: 0.5),
                 target: .inside(GoalZone(row: .middle, column: .center)), outcome: .goal,
                 date: Date(timeIntervalSince1970: Double(index)))
        }
        #expect(StatsEngine(shots: shots).shooterPatterns().contains { $0.kind == .repeatAfterGoal })
    }
    @Test func numberReuseCannotInventRepeatAfterGoalPairs() {
        let shots = (0..<5).map { index in
            Shot(attackingSide: .rival, shooter: Player(id: UUID(), number: 7),
                 originPoint: CourtPoint(x: 0.5, y: 0.5),
                 target: .inside(GoalZone(row: .middle, column: .center)), outcome: .goal,
                 date: Date(timeIntervalSince1970: Double(index)))
        }
        #expect(!StatsEngine(shots: shots).shooterPatterns().contains { $0.kind == .repeatAfterGoal })
    }
    @Test func snapshotSurvivesRenumberingAndNumberReuse() throws {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let first = Player(id: id, number: 7, name: "Ana", handedness: .left)
        let snapshot = try MatchRoster(players: [first])
        let edited = Player(id: id, number: 9, name: "New name", handedness: .right)
        let other = Player(id: UUID(), number: 7)
        let current = try MatchRoster(players: [edited, other])
        #expect(snapshot.players == [first])
        #expect(snapshot.player(id: id)?.number == 7)
        #expect(current.player(id: id)?.number == 9)
    }

    @Test func rejectsMissingIdentityDuplicateIdentityAndInvalidNumbers() throws {
        let id = UUID()
        #expect(throws: MatchRosterError.missingIdentity) { try MatchRoster(players: [Player(number: 7)]) }
        #expect(throws: MatchRosterError.duplicateIdentity(id)) {
            try MatchRoster(players: [Player(id: id, number: 7), Player(id: id, number: 9)])
        }
        #expect(throws: RosterError.duplicateNumber(7)) {
            try MatchRoster(players: [Player(id: UUID(), number: 7), Player(id: UUID(), number: 7)])
        }
        #expect(throws: RosterError.numberOutOfRange(number: 100, allowedRange: 1...99)) {
            try MatchRoster(players: [Player(id: id, number: 100)])
        }
        #expect(try MatchRoster(players: []).players.isEmpty)
    }

    @Test func statisticsFollowPeopleNotNumbers() {
        let id = UUID()
        let other = UUID()
        func shot(_ player: Player, _ side: AttackingSide = .rival) -> Shot {
            Shot(attackingSide: side, shooter: side == .rival ? player : nil,
                 facingGoalkeeper: side == .own ? player : nil,
                 target: .inside(GoalZone(row: .middle, column: .center)), outcome: .goal, date: Date(timeIntervalSince1970: 0))
        }
        let engine = StatsEngine(shots: [shot(Player(id: id, number: 7)), shot(Player(id: id, number: 9)),
                                         shot(Player(id: other, number: 7)), shot(Player(id: id, number: 1), .own)])
        #expect(engine.shots(by: id).shots.count == 2)
        #expect(engine.shots(facing: id).shots.count == 1)
        #expect(engine.shots(by: UUID()).shots.isEmpty)
        #expect(Player(number: 7) == Player(number: 7))
    }
}

import Foundation
import Testing
@testable import KeepercentDomain

struct MatchRosterTests {
    @Test func selectionDraftRetainsEditedNumberAcrossRepeatedToggles() throws {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let otherID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let player = Player(id: id, number: 7, name: "Ana", isGoalkeeper: true, handedness: .left)
        let other = Player(id: otherID, number: 12, name: "Bea")
        var draft = MatchRosterDraft(available: [other, player], selected: [player, other])
        draft.setNumber(9, for: id)
        for _ in 0..<3 {
            draft.setIncluded(false, for: id)
            #expect(draft.selectedPlayers == [other])
            #expect(draft.player(id: id)?.number == 9)
            draft.setIncluded(true, for: id)
            draft.setIncluded(true, for: id)
            #expect(draft.selectedPlayers.count == 2)
            #expect(draft.player(id: otherID) == other)
            #expect(draft.choices == [player, other])
        }
        let saved = try MatchRoster(players: draft.selectedPlayers)
        #expect(saved.player(id: id) == Player(id: id, number: 9, name: "Ana", isGoalkeeper: true, handedness: .left))
        #expect(saved.player(id: otherID) == other)
    }

    @Test func rosterEditPreservesIdentityEvenWithNumberOnlyDraft() throws {
        let id = UUID()
        let original = Player(id: id, number: 7)
        let roster = try Roster(players: [original])
        let edited = try roster.update(number: 7, to: Player(number: 9, name: "Ana"))
        #expect(edited.player(number: 9)?.id == id)
    }

    @Test func selectionDraftPrefersSnapshotsAndKeepsInitialTieBreakOrder() {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let otherID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let snapshot = Player(id: id, number: 7, name: "Recorded", handedness: .left)
        let current = Player(id: id, number: 99, name: "Current", handedness: .right)
        let other = Player(id: otherID, number: 7)
        var draft = MatchRosterDraft(available: [other, current, other], selected: [snapshot])
        #expect(draft.choices == [snapshot, other])
        #expect(draft.player(id: id) == snapshot)
        draft.setNumber(90, for: id)
        draft.setIncluded(true, for: otherID)
        draft.setNumber(1, for: otherID)
        #expect(draft.choices == [snapshot, other])
        #expect(draft.player(id: id)?.name == "Recorded")
        #expect(draft.player(id: id)?.handedness == .left)
    }

    @Test func selectionDraftLocksParticipantsButAllowsDeliberateAdditions() throws {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let additionID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let snapshot = Player(id: id, number: 7)
        let addition = Player(id: additionID, number: 12)
        var draft = MatchRosterDraft(available: [addition], selected: [snapshot], lockedIDs: [id])
        draft.setIncluded(false, for: id)
        draft.setNumber(9, for: id)
        #expect(draft.selectedPlayers == [snapshot])
        #expect(draft.player(id: id) == snapshot)
        draft.setIncluded(true, for: additionID)
        draft.setNumber(15, for: additionID)
        draft.setIncluded(false, for: additionID)
        draft.setIncluded(true, for: additionID)
        let saved = try MatchRoster(players: draft.selectedPlayers)
        #expect(saved.player(id: id) == snapshot)
        #expect(saved.player(id: additionID)?.number == 15)
        let lockedSuggestion = MatchRosterDraft(available: [snapshot], selected: [], lockedIDs: [id])
        #expect(lockedSuggestion.isSelected(id))
    }

    @Test func selectionDraftDefersDuplicateAndInvalidNumberValidationUntilSave() throws {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let otherID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let players = [Player(id: id, number: 7), Player(id: otherID, number: 9)]
        var draft = MatchRosterDraft(available: players, selected: players)
        draft.setNumber(9, for: id)
        draft.setIncluded(false, for: id)
        draft.setIncluded(true, for: id)
        #expect(draft.player(id: id)?.number == 9)
        #expect(throws: RosterError.duplicateNumber(9)) { try MatchRoster(players: draft.selectedPlayers) }
        for number in [0, 100] {
            draft.setNumber(number, for: id)
            #expect(draft.player(id: id)?.number == number)
            #expect(throws: RosterError.numberOutOfRange(number: number, allowedRange: 1...99)) {
                try MatchRoster(players: draft.selectedPlayers)
            }
        }
        draft.setNumber(8, for: id)
        #expect(try MatchRoster(players: draft.selectedPlayers).player(id: id)?.number == 8)
    }

    @Test func selectionDraftIgnoresUnknownEditsWithoutHidingMalformedSelectedValues() {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let unknownID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let player = Player(id: id, number: 7)
        let unidentified = Player(number: 12)
        var draft = MatchRosterDraft(available: [unidentified, player], selected: [unidentified, player])
        #expect(draft.choices == [player])
        #expect(draft.player(id: unknownID) == nil)
        draft.setIncluded(true, for: unknownID)
        draft.setIncluded(false, for: unknownID)
        draft.setNumber(9, for: unknownID)
        #expect(draft.selectedPlayers == [unidentified, player])
        #expect(throws: MatchRosterError.missingIdentity) { try MatchRoster(players: draft.selectedPlayers) }
        let duplicate = MatchRosterDraft(available: [], selected: [player, player])
        #expect(throws: MatchRosterError.duplicateIdentity(id)) { try MatchRoster(players: duplicate.selectedPlayers) }
    }

    @Test func selectionDraftDoesNotInferAttendanceOrEditDeselectedPeople() {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let player = Player(id: id, number: 7)
        var draft = MatchRosterDraft(available: [player], selected: [])
        #expect(draft.selectedPlayers.isEmpty)
        draft.setNumber(9, for: id)
        #expect(draft.player(id: id) == player)
        draft.setIncluded(true, for: id)
        #expect(draft.selectedPlayers == [player])
    }

    @Test func selectionDraftCopiesKeepCancellationIsolated() {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let player = Player(id: id, number: 7)
        let roster = [player]
        let original = MatchRosterDraft(available: roster, selected: roster)
        var editing = original
        editing.setNumber(9, for: id)
        editing.setIncluded(false, for: id)
        #expect(original.player(id: id) == player)
        #expect(original.selectedPlayers == roster)
        #expect(roster == [player])
        #expect(editing.player(id: id)?.number == 9)
        #expect(editing.selectedPlayers.isEmpty)
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

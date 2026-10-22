import Foundation
import Testing
@testable import KeepercentDomain

/// S1/S2: run unchanged against baseline and candidate shared domain contracts.
struct T73SharedContractRegressionTests {
    @Test func bulkSelectionKeepsLockedFactsAndDeselectedNumberDrafts() throws {
        let locked = Player(id: UUID(), number: 1, name: "Historical", isGoalkeeper: true)
        let changed = Player(id: locked.id, number: 99, name: "Current")
        let editable = Player(id: UUID(), number: 7, name: "Editable")
        var draft = MatchRosterDraft(available: [changed, editable], selected: [locked, editable], lockedIDs: [locked.id!])
        draft.setNumber(12, for: editable.id!)
        for player in draft.choices { draft.setIncluded(false, for: player.id!) }
        #expect(draft.selectedPlayers == [locked])
        draft.setNumber(50, for: locked.id!)
        draft.setNumber(20, for: editable.id!) // Deselected edits are intentionally ignored.
        for player in draft.choices { draft.setIncluded(true, for: player.id!) }
        for player in draft.choices { draft.setIncluded(true, for: player.id!) }
        #expect(draft.selectedPlayers.count == 2)
        #expect(draft.player(id: locked.id!) == locked)
        #expect(draft.player(id: editable.id!)?.number == 12)
        #expect(try MatchRoster(players: draft.selectedPlayers).players.count == 2)
        #expect(try MatchRoster(players: []).players.isEmpty)
        #expect(MatchRosterDraft(available: [], selected: []).choices.isEmpty)
    }

    @Test func invalidRosterNumbersAndIdentitiesStillRejectWithTypedErrors() throws {
        let id = UUID()
        for number in [-1, 0, 100] {
            #expect(throws: RosterError.numberOutOfRange(number: number, allowedRange: 1...99)) {
                try MatchRoster(players: [Player(id: id, number: number)])
            }
        }
        for number in [1, 99] {
            #expect(try MatchRoster(players: [Player(id: id, number: number)]).players[0].number == number)
        }
        #expect(throws: MatchRosterError.missingIdentity) { try MatchRoster(players: [Player(number: 7)]) }
        #expect(throws: MatchRosterError.duplicateIdentity(id)) {
            try MatchRoster(players: [Player(id: id, number: 7), Player(id: id, number: 8)])
        }
        #expect(throws: RosterError.duplicateNumber(7)) {
            try MatchRoster(players: [Player(id: id, number: 7), Player(id: UUID(), number: 7)])
        }
    }

    @Test func teamAndSessionValidationRemainBaselineCompatible() throws {
        for name in ["", " \n\t "] {
            #expect(throws: RivalTeamError.blankName) { try RivalTeam(name: name) }
        }
        #expect(try RivalTeam(name: "  Team 🥅  ").name == "Team 🥅")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let today = Date(timeIntervalSince1970: 1_700_000_000)
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today))!.addingTimeInterval(-1)
        for kind in SessionKind.allCases {
            for date in [Date(timeIntervalSince1970: 0), today, end] {
                #expect(try Session(kind: kind, matchDate: date, today: today, calendar: calendar).matchDate == date)
            }
            #expect(throws: SessionError.matchDateInFuture) {
                try Session(kind: kind, matchDate: end.addingTimeInterval(1), today: today, calendar: calendar)
            }
        }
    }
}

import Testing
@testable import KeepercentDomain

@Suite("Roster.add")
struct RosterAddTests {

    @Test("Adding a duplicate number is rejected and the roster is unchanged")
    func duplicateNumberRejected() throws {
        let roster = try Roster().add(Player(number: 7, name: "Ana"))

        #expect(throws: RosterError.duplicateNumber(7)) {
            try roster.add(Player(number: 7, name: "Bea"))
        }
        // The roster itself must still hold only the original player: the
        // error alone does not prove the mutation was rejected rather than
        // silently applied and then separately flagged.
        #expect(roster.players.map(\.number) == [7])
        #expect(roster.player(number: 7)?.name == "Ana")
    }

    @Test(
        "Boundary shirt numbers",
        arguments: [
            (number: 1, accepted: true),
            (number: 99, accepted: true),
            (number: 0, accepted: false),
            (number: 100, accepted: false),
            (number: -1, accepted: false)
        ]
    )
    func boundaryNumbers(input: (number: Int, accepted: Bool)) throws {
        if input.accepted {
            let roster = try Roster().add(Player(number: input.number))
            #expect(roster.player(number: input.number) != nil)
        } else {
            let empty = Roster()
            #expect(throws: RosterError.numberOutOfRange(number: input.number, allowedRange: Roster.numberRange)) {
                try empty.add(Player(number: input.number))
            }
            #expect(empty.players.isEmpty)
        }
    }
}

@Suite("Roster.addUnknown")
struct RosterAddUnknownTests {

    @Test("Produces a nameless, non-goalkeeper player with no handedness")
    func producesExpectedShape() throws {
        let roster = try Roster().addUnknown(number: 42)
        let player = try #require(roster.player(number: 42))

        #expect(player.number == 42)
        #expect(player.name == nil)
        #expect(player.isGoalkeeper == false)
        #expect(player.handedness == nil)
    }

    @Test("Still rejects a duplicate number")
    func stillRejectsDuplicates() throws {
        let roster = try Roster().addUnknown(number: 5)

        #expect(throws: RosterError.duplicateNumber(5)) {
            try roster.addUnknown(number: 5)
        }
    }

    @Test("Still rejects an out-of-range number")
    func stillRejectsOutOfRange() {
        let empty = Roster()
        #expect(throws: RosterError.numberOutOfRange(number: 0, allowedRange: Roster.numberRange)) {
            try empty.addUnknown(number: 0)
        }
    }
}

@Suite("Roster.remove")
struct RosterRemoveTests {

    @Test("Removing a player with 0 recorded shots succeeds")
    func zeroShotsSucceeds() throws {
        let roster = try Roster().add(Player(number: 7, name: "Ana"))
        let updated = try roster.remove(number: 7, recordedShotCount: 0)
        #expect(updated.player(number: 7) == nil)
        #expect(updated.players.isEmpty)
    }

    @Test("Removing a player with 1 recorded shot is rejected, the roster is unchanged, and the error carries both the number and the count")
    func recordedShotBlocksRemoval() throws {
        let roster = try Roster().add(Player(number: 7, name: "Ana"))

        #expect(throws: RosterError.playerHasRecordedShots(number: 7, shotCount: 1)) {
            try roster.remove(number: 7, recordedShotCount: 1)
        }
        // Same load-bearing check as duplicate-add: the player must still
        // be there, not just an error thrown alongside a silent removal.
        #expect(roster.player(number: 7) != nil)
        #expect(roster.players.map(\.number) == [7])
    }

    @Test(
        "Any nonzero shot count blocks removal, with that exact count in the error",
        arguments: [1, 2, 50]
    )
    func anyNonzeroCountBlocks(shotCount: Int) throws {
        let roster = try Roster().add(Player(number: 3, name: "Bea"))
        #expect(throws: RosterError.playerHasRecordedShots(number: 3, shotCount: shotCount)) {
            try roster.remove(number: 3, recordedShotCount: shotCount)
        }
    }

    @Test("Removing a player not in the roster errors instead of doing nothing")
    func notInRosterErrors() {
        let roster = Roster()
        #expect(throws: RosterError.playerNotFound(number: 9)) {
            try roster.remove(number: 9, recordedShotCount: 0)
        }
    }

    @Test("A missing player is reported as missing even when a shot count is passed")
    func missingPlayerWinsOverShotCount() {
        // The existence guard runs before the shot-count guard, so this
        // reports the number nobody wears rather than claiming that a
        // player who is not here has shots. The order is what the editor
        // actually shows the user, so it is pinned rather than left to
        // whichever guard happens to come first after a future edit.
        let roster = Roster()
        #expect(throws: RosterError.playerNotFound(number: 9)) {
            try roster.remove(number: 9, recordedShotCount: 5)
        }
    }
}

@Suite("Roster.update")
struct RosterUpdateTests {

    @Test("Renumbering to a free number succeeds")
    func renumberToFreeNumberSucceeds() throws {
        let roster = try Roster().add(Player(number: 7, name: "Ana"))
        let updated = try roster.update(number: 7, to: Player(number: 8, name: "Ana"))

        #expect(updated.player(number: 7) == nil)
        #expect(updated.player(number: 8)?.name == "Ana")
    }

    @Test("Renumbering to a number already taken by a different player is rejected")
    func renumberToTakenNumberRejected() throws {
        let roster = try Roster()
            .add(Player(number: 7, name: "Ana"))
            .add(Player(number: 8, name: "Bea"))

        #expect(throws: RosterError.duplicateNumber(8)) {
            try roster.update(number: 7, to: Player(number: 8, name: "Ana"))
        }
        // Unchanged: both original players still exactly where they were.
        #expect(roster.player(number: 7)?.name == "Ana")
        #expect(roster.player(number: 8)?.name == "Bea")
    }

    @Test("\"Renumbering\" to the player's own current number succeeds and is not a self-conflict")
    func renumberToOwnNumberSucceeds() throws {
        let roster = try Roster().add(Player(number: 7, name: "Ana", isGoalkeeper: false))
        let updated = try roster.update(number: 7, to: Player(number: 7, name: "Ana", isGoalkeeper: true))

        #expect(updated.player(number: 7)?.isGoalkeeper == true)
        #expect(updated.players.map(\.number) == [7])
    }

    @Test("Updates name, goalkeeper flag and handedness")
    func updatesOtherFields() throws {
        let roster = try Roster().add(Player(number: 1, name: nil, isGoalkeeper: false, handedness: nil))
        let updated = try roster.update(
            number: 1,
            to: Player(number: 1, name: "Carla", isGoalkeeper: true, handedness: .left)
        )
        let player = try #require(updated.player(number: 1))

        #expect(player.name == "Carla")
        #expect(player.isGoalkeeper == true)
        #expect(player.handedness == .left)
    }

    @Test("Updating a player not in the roster errors")
    func updatingMissingPlayerErrors() {
        let roster = Roster()
        #expect(throws: RosterError.playerNotFound(number: 4)) {
            try roster.update(number: 4, to: Player(number: 4, name: "Ghost"))
        }
    }

    @Test("A missing player is reported as missing even when the new number is also out of range")
    func missingPlayerWinsOverOutOfRange() {
        // Two rules are broken at once. The existence guard runs before
        // validate(number:replacing:), so the answer names the player who
        // is not there rather than the range — the first thing the user
        // has to fix, not the second. Same reason as the remove ordering
        // above: this is observable behaviour, so it gets a test.
        let roster = Roster()
        #expect(throws: RosterError.playerNotFound(number: 4)) {
            try roster.update(number: 4, to: Player(number: 100, name: "Ghost"))
        }
    }

    @Test("Renumbering to an out-of-range number is rejected")
    func renumberOutOfRangeRejected() throws {
        let roster = try Roster().add(Player(number: 7, name: "Ana"))
        #expect(throws: RosterError.numberOutOfRange(number: 100, allowedRange: Roster.numberRange)) {
            try roster.update(number: 7, to: Player(number: 100, name: "Ana"))
        }
        #expect(roster.player(number: 7) != nil)
    }
}

@Suite("Roster.players sorting")
struct RosterSortingTests {

    @Test("Players come back sorted by shirt number, including across the 9/10 boundary")
    func sortedAcrossNineTenBoundary() throws {
        let roster = try Roster()
            .add(Player(number: 10, name: "Ten"))
            .add(Player(number: 2, name: "Two"))
            .add(Player(number: 9, name: "Nine"))
            .add(Player(number: 1, name: "One"))

        // A naive string sort would put "1", "10", "2", "9" in that order;
        // a correct numeric sort must not.
        #expect(roster.players.map(\.number) == [1, 2, 9, 10])
    }
}

@Suite("Roster.init(players:)")
struct RosterBulkInitTests {

    @Test("Builds a roster from stored players and sorts them numerically")
    func buildsFromStoredPlayers() throws {
        let roster = try Roster(players: [
            Player(number: 12, name: "Twelve", isGoalkeeper: true),
            Player(number: 3, name: "Three"),
            Player(number: 7, name: "Seven", handedness: .left),
        ])

        #expect(roster.players.map(\.number) == [3, 7, 12])
        let keeper = try #require(roster.player(number: 12))
        #expect(keeper.isGoalkeeper)
        let seven = try #require(roster.player(number: 7))
        #expect(seven.handedness == .left)
    }

    @Test("An empty array builds an empty roster rather than failing")
    func emptyArrayBuildsEmptyRoster() throws {
        let roster = try Roster(players: [])
        #expect(roster.players.isEmpty)
    }

    @Test("A duplicate shirt number throws instead of silently dropping a row")
    func duplicateNumberThrows() {
        // Dropping the second row would leave a roster one player short,
        // and every statistic derived from the player who vanished would be
        // misattributed to whoever kept the number.
        #expect(throws: RosterError.duplicateNumber(7)) {
            _ = try Roster(players: [
                Player(number: 7, name: "First"),
                Player(number: 7, name: "Second"),
            ])
        }
    }

    @Test("An out-of-range shirt number throws, carrying the legal range")
    func outOfRangeThrows() {
        #expect(throws: RosterError.numberOutOfRange(number: 100, allowedRange: 1...99)) {
            _ = try Roster(players: [Player(number: 100)])
        }
    }
}

@Suite("RivalTeam name validation")
struct RivalTeamNameTests {

    @Test("An empty name is rejected")
    func emptyNameRejected() {
        #expect(throws: RivalTeamError.blankName) {
            try RivalTeam(name: "")
        }
    }

    @Test("A whitespace-only name is rejected")
    func whitespaceOnlyNameRejected() {
        #expect(throws: RivalTeamError.blankName) {
            try RivalTeam(name: "   \n\t")
        }
    }

    @Test("Surrounding whitespace is trimmed on a valid name")
    func surroundingWhitespaceTrimmed() throws {
        let team = try RivalTeam(name: "  CB Handball  ")
        #expect(team.name == "CB Handball")
    }
}

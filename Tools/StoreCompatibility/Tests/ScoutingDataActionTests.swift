import Foundation
import SwiftData
import Testing
import KeepercentDomain
@testable import ProductionStore

@MainActor struct ScoutingDataActionTests {
    @Test func renameValidatesAndPreservesHistory() throws {
        let (container, team, match, _) = try fixture()
        let context = container.mainContext
        let playerID = team.players[0].persistentModelID
        let shotID = match.shots[0].persistentModelID
        try ScoutingDataActions.rename(team, to: "  Renamed  ", in: context)
        #expect(team.name == "Renamed")
        #expect(team.players[0].persistentModelID == playerID)
        #expect(match.shots[0].persistentModelID == shotID)
        #expect(throws: RivalTeamError.blankName) {
            try ScoutingDataActions.rename(team, to: " \n ", in: context)
        }
        #expect(team.name == "Renamed" && team.sessions.count == 2)
        #expect(match.shots[0].persistentModelID == shotID)
        #expect(!context.hasChanges)
    }

    @Test func editValidatesBeforeWritingAndPreservesMatchFacts() throws {
        let (container, team, match, other) = try fixture()
        let context = container.mainContext
        let originalDate = match.date
        let shotID = match.shots[0].persistentModelID
        let snapshotID = match.participants[0].persistentModelID
        #expect(throws: SessionError.matchDateInFuture) {
            try ScoutingDataActions.edit(match, kind: .video,
                date: .distantFuture, in: context)
        }
        #expect(match.date == originalDate && match.kindCode == "live")
        #expect(!context.hasChanges)
        let earlier = Date(timeIntervalSince1970: 1_600_000_000)
        try ScoutingDataActions.edit(match, kind: .video, date: earlier, in: context)
        #expect(match.date == earlier && match.kindCode == "video")
        #expect(match.rivalTeam === team && match.shots[0].persistentModelID == shotID)
        #expect(match.participants[0].persistentModelID == snapshotID)
        #expect(other.kindCode == "live" && other.date == originalDate)
    }

    @Test func deleteMatchRemovesOnlyItsOwnedRows() throws {
        let (container, team, match, other) = try fixture()
        let context = container.mainContext
        let removedShotID = match.shots[0].persistentModelID
        let removedSnapshotID = match.participants[0].persistentModelID
        try ScoutingDataActions.delete(match, in: context)
        #expect(try context.fetch(FetchDescriptor<StoredSession>()).map(\.persistentModelID) == [other.persistentModelID])
        let shots = try context.fetch(FetchDescriptor<StoredShot>())
        let participants = try context.fetch(FetchDescriptor<StoredMatchParticipant>())
        #expect(shots.count == 1 && !shots.contains { $0.persistentModelID == removedShotID })
        #expect(participants.count == 2 && !participants.contains { $0.persistentModelID == removedSnapshotID })
        #expect(team.players.count == 1 && team.sessions.count == 1)
        #expect(other.shots.count == 1 && other.participants.count == 1 && other.ownParticipants.count == 1)
        #expect(try context.fetchCount(FetchDescriptor<StoredOwnTeam>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<StoredPlayer>()) == 2)
        #expect(other.shots[0].shooter === team.players[0])
    }

    @Test func deleteTeamKeepsMatchesShotsAndSnapshotIdentity() throws {
        let (container, team, match, other) = try fixture()
        let context = container.mainContext
        let shotID = match.shots[0].persistentModelID
        let personID = match.participants[0].personID
        try ScoutingDataActions.delete(team, in: context)
        #expect(try context.fetch(FetchDescriptor<StoredRivalTeam>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<StoredPlayer>()).count == 1)
        #expect(try context.fetchCount(FetchDescriptor<StoredSession>()) == 2)
        #expect(try context.fetchCount(FetchDescriptor<StoredShot>()) == 2)
        #expect(try context.fetchCount(FetchDescriptor<StoredMatchParticipant>()) == 4)
        #expect(match.rivalTeam == nil && other.rivalTeam == nil)
        #expect(match.shots[0].persistentModelID == shotID && match.shots[0].shooter == nil)
        #expect(match.shots[0].shooterSnapshot?.personID == personID)
        #expect(match.shots[0].domainShot?.shooter?.name == "Original")
        #expect(match.ownParticipants.count == 1 && match.ownTeam?.name == "Own Club")
    }

    @Test func diskReopenPreservesScopedDeletesAndRollsBackFailedSaves() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("keepercent-t73-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        print("T7.3 disposable store: \(directory.path)")
        let schema = Schema(KeepercentSchema.models)
        let url = directory.appendingPathComponent("test.store")
        do {
            let (container, team, match, _) = try fixture(configuration: ModelConfiguration(schema: schema, url: url))
            try ScoutingDataActions.rename(team, to: "Persisted", in: container.mainContext)
            try ScoutingDataActions.edit(match, kind: .video, date: match.date, in: container.mainContext)
            try ScoutingDataActions.delete(match, in: container.mainContext)
        }
        do {
            let container = try ModelContainer(for: schema,
                configurations: ModelConfiguration(schema: schema, url: url, allowsSave: false))
            let context = container.mainContext
            let team = try #require(context.fetch(FetchDescriptor<StoredRivalTeam>()).first)
            #expect(throws: (any Error).self) {
                try ScoutingDataActions.rename(team, to: "Must Not Persist", in: context)
            }
            #expect(team.name == "Persisted" && !context.hasChanges)
        }
        do {
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
            let context = container.mainContext
            let team = try #require(context.fetch(FetchDescriptor<StoredRivalTeam>()).first)
            #expect(team.name == "Persisted")
            #expect(try context.fetchCount(FetchDescriptor<StoredSession>()) == 1)
            #expect(try context.fetchCount(FetchDescriptor<StoredShot>()) == 1)
            #expect(try context.fetchCount(FetchDescriptor<StoredMatchParticipant>()) == 2)
            try ScoutingDataActions.delete(team, in: context)
        }
        let reopened = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
        let context = reopened.mainContext
        let match = try #require(context.fetch(FetchDescriptor<StoredSession>()).first)
        #expect(match.rivalTeam == nil && match.shots.count == 1)
        #expect(match.shots[0].domainShot?.shooter?.name == "Original")
        #expect(match.ownTeam?.name == "Own Club" && match.ownParticipants.count == 1)
    }

    private func fixture(configuration: ModelConfiguration? = nil) throws -> (ModelContainer, StoredRivalTeam, StoredSession, StoredSession) {
        let schema = Schema(KeepercentSchema.models)
        let container = try ModelContainer(for: schema,
            configurations: configuration ?? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let context = container.mainContext
        let team = StoredRivalTeam(name: "Rival")
        let player = StoredPlayer(number: 7, name: "Original", isGoalkeeper: false, handednessCode: "right")
        team.players = [player]
        context.insert(team)
        let ownTeam = StoredOwnTeam(name: "Own Club")
        let ownPlayer = StoredPlayer(number: 1, name: "Own Keeper", isGoalkeeper: true, handednessCode: nil)
        ownTeam.players = [ownPlayer]
        context.insert(ownTeam)
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        var matches: [StoredSession] = []
        for _ in 0..<2 {
            let match = StoredSession(date: date, kindCode: "live", rivalTeam: team)
            let participant = StoredMatchParticipant(player.domainPlayer)
            match.participants = [participant]
            match.ownTeam = ownTeam
            match.ownParticipants = [StoredMatchParticipant(ownPlayer.domainPlayer)]
            let shot = try Shot.record(attackingSide: .rival, shooter: player.domainPlayer,
                activeRivalGoalkeeper: nil, originPoint: nil, isSevenMeters: true,
                target: .inside(GoalZone(row: .middle, column: .center)), outcome: .goal, date: date)
            let stored = StoredShot(shot, shooter: player, facingGoalkeeper: nil)
            stored.shooterSnapshot = participant
            match.shots = [stored]
            team.sessions.append(match)
            context.insert(match)
            matches.append(match)
        }
        try context.save()
        return (container, team, matches[0], matches[1])
    }
}

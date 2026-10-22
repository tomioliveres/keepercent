import Foundation
import SwiftData
import Testing
import CryptoKit
import KeepercentDomain
@testable import ProductionStore

/// S1/S2: independent disk, identity, statistics and failed-save regressions.
@MainActor struct IndependentScoutingDataActionTests {
    private let schema = Schema(KeepercentSchema.models)

    private func location() throws -> URL {
        let root = try #require(ProcessInfo.processInfo.environment["TMPDIR"])
        let directory = URL(fileURLWithPath: root).appendingPathComponent("t73-probe-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        print("Independent T7.3 store: \(directory.path)")
        return directory.appendingPathComponent("probe.store")
    }

    private func open(_ url: URL, readOnly: Bool = false) throws -> ModelContainer {
        try ModelContainer(for: schema, configurations:
            ModelConfiguration(schema: schema, url: url, allowsSave: !readOnly))
    }

    private func seed(_ url: URL) throws {
        let container = try open(url)
        let context = container.mainContext
        context.autosaveEnabled = false
        let own = StoredOwnTeam(name: "Own")
        let keeper = StoredPlayer(number: 1, name: "Own keeper", isGoalkeeper: true, handednessCode: nil)
        own.players = [keeper]
        context.insert(own)
        for name in ["Target", "Unrelated"] {
            let rival = StoredRivalTeam(name: name)
            let player = StoredPlayer(number: 7, name: name + " player", isGoalkeeper: false, handednessCode: "right")
            rival.players = [player]
            context.insert(rival)
            for index in 0..<2 {
                let match = StoredSession(date: Date(timeIntervalSince1970: Double(1_600_000_000 + index)),
                                          kindCode: "live", rivalTeam: rival)
                match.ownTeam = own
                let snapshot = StoredMatchParticipant(player.domainPlayer)
                let ownSnapshot = StoredMatchParticipant(keeper.domainPlayer)
                match.participants = [snapshot]
                match.ownParticipants = [ownSnapshot]
                let shot = try Shot.record(attackingSide: .rival, shooter: player.domainPlayer,
                    activeRivalGoalkeeper: nil, ownGoalkeeper: keeper.domainPlayer,
                    originPoint: nil, isSevenMeters: true,
                    target: .inside(GoalZone(row: .middle, column: .center)), outcome: .goal, date: match.date)
                let row = StoredShot(shot, shooter: player, facingGoalkeeper: nil, ownGoalkeeper: keeper)
                row.shooterSnapshot = snapshot
                row.ownGoalkeeperSnapshot = ownSnapshot
                match.shots = [row]
                rival.sessions.append(match)
                context.insert(match)
            }
        }
        try context.save()
    }

    private func id(_ model: (any PersistentModel)?) -> String {
        guard let model else { return "nil" }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try! encoder.encode(model.persistentModelID).base64EncodedString()
    }

    private func graph(_ context: ModelContext) throws -> [String] {
        var rows: [String] = []
        for x in try context.fetch(FetchDescriptor<StoredRivalTeam>()) {
            rows.append("r|\(id(x))|\(x.name)|\(x.createdAt)|\(x.players.map { id($0) }.sorted())|\(x.sessions.map { id($0) }.sorted())")
        }
        for x in try context.fetch(FetchDescriptor<StoredOwnTeam>()) {
            rows.append("o|\(id(x))|\(x.name)|\(x.createdAt)|\(x.players.map { id($0) }.sorted())|\(x.sessions.map { id($0) }.sorted())")
        }
        for x in try context.fetch(FetchDescriptor<StoredPlayer>()) {
            rows.append("p|\(id(x))|\(String(describing: x.personID))|\(x.number)|\(String(describing: x.name))|\(x.isGoalkeeper)|\(String(describing: x.handednessCode))|\(String(describing: x.archivedAt))")
        }
        for x in try context.fetch(FetchDescriptor<StoredSession>()) {
            rows.append("m|\(id(x))|\(String(describing: x.matchID))|\(x.date)|\(x.kindCode)|\(id(x.rivalTeam))|\(id(x.ownTeam))|\(x.shots.map { id($0) }.sorted())|\(x.participants.map { id($0) }.sorted())|\(x.ownParticipants.map { id($0) }.sorted())")
        }
        for x in try context.fetch(FetchDescriptor<StoredMatchParticipant>()) {
            rows.append("s|\(id(x))|\(x.personID)|\(x.number)|\(String(describing: x.name))|\(x.isGoalkeeper)|\(String(describing: x.handednessCode))")
        }
        for x in try context.fetch(FetchDescriptor<StoredShot>()) {
            rows.append("h|\(id(x))|\(x.date)|\(x.attackingSideCode)|\(String(describing: x.originX))|\(String(describing: x.originY))|\(x.isSevenMeters)|\(x.targetCode)|\(x.outcomeCode)|\(String(describing: x.deliveryCode))|\(String(describing: x.approachCode))|\(id(x.shooter))|\(id(x.facingGoalkeeper))|\(id(x.ownShooter))|\(id(x.ownGoalkeeper))|\(id(x.shooterSnapshot))|\(id(x.goalkeeperSnapshot))|\(id(x.ownShooterSnapshot))|\(id(x.ownGoalkeeperSnapshot))")
        }
        return rows.sorted()
    }

    /// Hash database and WAL bytes, not transient shared-memory lock bookkeeping.
    private func hashes(_ url: URL) throws -> [String: Data] {
        var result: [String: Data] = [:]
        for suffix in ["", "-wal"] {
            let path = URL(fileURLWithPath: url.path + suffix)
            if FileManager.default.fileExists(atPath: path.path) {
                result[suffix] = Data(SHA256.hash(data: try Data(contentsOf: path)))
            }
        }
        return result
    }

    @Test func rejectedAndFailedOperationsLeaveDiskAndGraphUnchanged() throws {
        let url = try location()
        try seed(url)
        for readOnly in [false, true] {
            let container = try open(url, readOnly: readOnly)
            let context = container.mainContext
            context.autosaveEnabled = false
            let team = try #require(context.fetch(FetchDescriptor<StoredRivalTeam>()).first { $0.name == "Target" })
            let match = try #require(team.sessions.first)
            let operations: [() throws -> Void]
            if readOnly {
                operations = [
                    { try ScoutingDataActions.rename(team, to: "Changed", in: context) },
                    { try ScoutingDataActions.edit(match, kind: .video, date: match.date, in: context) },
                    { try ScoutingDataActions.delete(match, in: context) },
                    { try ScoutingDataActions.delete(team, in: context) }
                ]
            } else {
                operations = [
                    { try ScoutingDataActions.rename(team, to: "", in: context) },
                    { try ScoutingDataActions.rename(team, to: " \n\t ", in: context) },
                    { try ScoutingDataActions.edit(match, kind: .video,
                        date: Calendar.current.date(byAdding: .day, value: 2, to: .now)!, in: context) }
                ]
            }
            for (index, operation) in operations.enumerated() {
                let before = try graph(context)
                let bytes = try hashes(url)
                do { try operation(); Issue.record("Operation unexpectedly succeeded") }
                catch {
                    if readOnly {
                        #expect((error as NSError).domain == NSCocoaErrorDomain)
                        #expect((error as NSError).code == 513)
                    } else if index < 2 { #expect(error as? RivalTeamError == .blankName) }
                    else { #expect(error as? SessionError == .matchDateInFuture) }
                }
                #expect(!context.hasChanges)
                #expect(try graph(context) == before)
                #expect(try hashes(url) == bytes)
                let reopened = try open(url, readOnly: true)
                let after = try graph(reopened.mainContext)
                #expect(after == before)
            }
        }
    }

    @Test(arguments: [false, true]) func successfulDeletesRemainScopedOnDisk(deleteTeam: Bool) throws {
        let url = try location()
        try seed(url)
        var expectedShots: [Shot] = []
        var expectedUnrelated: [String] = []
        var expectedMatchIDs = Set<UUID>()
        var removedMatchID: UUID?
        var expectedPlayerIDs = Set<UUID>()
        var expectedSnapshotIDs = Set<String>()
        do {
            let container = try open(url)
            let context = container.mainContext
            let team = try #require(context.fetch(FetchDescriptor<StoredRivalTeam>()).first { $0.name == "Target" })
            let match = try #require(team.sessions.first)
            let unrelated = try #require(context.fetch(FetchDescriptor<StoredRivalTeam>()).first { $0.name == "Unrelated" })
            expectedUnrelated = try graph(context).filter { $0.contains("Unrelated") }
            let surviving = try context.fetch(FetchDescriptor<StoredSession>()).filter { deleteTeam || $0 !== match }
            expectedMatchIDs = Set(surviving.compactMap(\.matchID))
            expectedShots = surviving.flatMap(\.shots).compactMap(\.domainShot)
            expectedSnapshotIDs = Set(surviving.flatMap { $0.participants + $0.ownParticipants }.map { id($0) })
            expectedPlayerIDs = Set((try context.fetch(FetchDescriptor<StoredPlayer>())).filter {
                !deleteTeam || !team.players.contains($0)
            }.compactMap(\.personID))
            removedMatchID = deleteTeam ? nil : match.matchID
            let unrelatedIDs = Set(unrelated.sessions.compactMap(\.matchID))
            if deleteTeam { try ScoutingDataActions.delete(team, in: context) }
            else { try ScoutingDataActions.delete(match, in: context) }
            #expect(Set(unrelated.sessions.compactMap(\.matchID)) == unrelatedIDs)
        }
        let reopened = try open(url)
        let context = reopened.mainContext
        let matches = try context.fetch(FetchDescriptor<StoredSession>())
        #expect(Set(matches.compactMap(\.matchID)) == expectedMatchIDs)
        #expect(Set(try context.fetch(FetchDescriptor<StoredPlayer>()).compactMap(\.personID)) == expectedPlayerIDs)
        let snapshotIDs = Set(try context.fetch(FetchDescriptor<StoredMatchParticipant>()).map { id($0) })
        #expect(snapshotIDs == expectedSnapshotIDs)
        #expect(try graph(context).filter { $0.contains("Unrelated") } == expectedUnrelated)
        let actual = try context.fetch(FetchDescriptor<StoredShot>()).compactMap(\.domainShot)
        #expect(Set(actual) == Set(expectedShots) && actual.count == expectedShots.count)
        #expect(StatsEngine(shots: actual).effectiveness == Tally(successes: deleteTeam ? 4 : 3, attempts: deleteTeam ? 4 : 3))
        let grouped = matches.compactMap { match in
            match.matchID.map { MatchShots(id: $0, shots: match.shots.compactMap(\.domainShot)) }
        }
        #expect(MatchScope.all.shots(in: grouped).count == actual.count)
        for match in grouped { #expect(MatchScope.match(match.id).shots(in: grouped) == match.shots) }
        if let removedMatchID { #expect(MatchScope.match(removedMatchID).shots(in: grouped).isEmpty) }
        let keeperID = try #require(context.fetch(FetchDescriptor<StoredOwnTeam>()).first?.players.first?.personID)
        #expect(StatsEngine(shots: actual).shots(facingOwnGoalkeeper: keeperID).shots.count == actual.count)
        #expect(matches.allSatisfy { $0.ownTeam?.name == "Own" && $0.ownParticipants.count == 1 })
        #expect(try context.fetchCount(FetchDescriptor<StoredOwnTeam>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<StoredRivalTeam>()) == (deleteTeam ? 1 : 2))
        if deleteTeam { #expect(matches.filter { $0.rivalTeam == nil }.count == 2) }
    }
    @Test func validEditsPreserveIdentityAndAllHistoricalFactsOnDisk() throws {
        let url = try location()
        try seed(url)
        var expected: [String] = []
        do {
            let container = try open(url)
            let context = container.mainContext
            let team = try #require(context.fetch(FetchDescriptor<StoredRivalTeam>()).first { $0.name == "Target" })
            let match = try #require(team.sessions.first)
            let teamID = team.persistentModelID
            let matchID = match.persistentModelID
            let createdAt = team.createdAt
            let historical = try graph(context).filter { !$0.hasPrefix("r|") && !$0.hasPrefix("m|") }
            let otherMatches = try context.fetch(FetchDescriptor<StoredSession>()).filter { $0 !== match }
            let otherFacts = otherMatches.map { "\($0.matchID!)|\($0.date)|\($0.kindCode)" }.sorted()
            let date = Date(timeIntervalSince1970: 1_500_000_000)
            try ScoutingDataActions.rename(team, to: "  Renamed 🥅  ", in: context)
            try ScoutingDataActions.edit(match, kind: .video, date: date, in: context)
            #expect(team.name == "Renamed 🥅" && team.createdAt == createdAt)
            #expect(team.persistentModelID == teamID && match.persistentModelID == matchID)
            #expect(match.date == date && match.kindCode == "video")
            #expect(try graph(context).filter { !$0.hasPrefix("r|") && !$0.hasPrefix("m|") } == historical)
            #expect(otherMatches.map { "\($0.matchID!)|\($0.date)|\($0.kindCode)" }.sorted() == otherFacts)
            expected = try graph(context)
        }
        let reopened = try open(url)
        #expect(try graph(reopened.mainContext) == expected)
    }

}

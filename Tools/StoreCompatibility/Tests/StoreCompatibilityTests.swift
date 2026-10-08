import Foundation
import SwiftData
import Testing
@testable import ProductionStore

struct StoreCompatibilityTests {
    @Test @MainActor func legacyDiskUpgradePreservesIdentityAndHistoryAfterReopen() throws {
        let path = try #require(ProcessInfo.processInfo.environment["KEEPERCENT_COMPATIBILITY_DIRECTORY"])
        let directory = URL(fileURLWithPath: path, isDirectory: true)
        let storeURL = directory.appendingPathComponent("legacy.store")
        let oldIDs = try JSONDecoder().decode([PersistentIdentifier].self,
                                              from: Data(contentsOf: directory.appendingPathComponent("identifiers.json")))
        let schema = Schema(KeepercentSchema.models)
        #expect(Set(schema.entities.map(\.name)) == Set(["StoredRivalTeam", "StoredPlayer", "StoredSession", "StoredShot", "StoredMatchParticipant", "StoredOwnTeam"]))
        func open() throws -> ModelContainer {
            try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: storeURL)])
        }
        var shooterID: UUID?
        var matchID: UUID?
        do {
            let container = try open()
            let context = ModelContext(container)
            let teams = try context.fetch(FetchDescriptor<StoredRivalTeam>())
            let players = try context.fetch(FetchDescriptor<StoredPlayer>())
            let sessions = try context.fetch(FetchDescriptor<StoredSession>())
            let shots = try context.fetch(FetchDescriptor<StoredShot>())
            #expect(teams.count == 1 && players.count == 3 && sessions.count == 2 && shots.count == 3)
            #expect(try context.fetch(FetchDescriptor<StoredOwnTeam>()).isEmpty)
            #expect(sessions.allSatisfy { $0.ownTeam == nil && $0.ownParticipants.isEmpty })
            #expect(shots.allSatisfy { $0.ownShooter == nil && $0.ownGoalkeeper == nil && $0.ownShooterSnapshot == nil && $0.ownGoalkeeperSnapshot == nil })
            let currentIDs = Set(teams.map(\.persistentModelID) + players.map(\.persistentModelID) + sessions.map(\.persistentModelID) + shots.map(\.persistentModelID))
            // Decoded IDs and managed-object-backed IDs have different backing
            // implementations. Compare their complete canonical persisted encoding,
            // including store UUID, entity and primary key, not wrapper equality.
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            #expect(try Set(currentIDs.map { try encoder.encode($0) }) == Set(oldIDs.map { try encoder.encode($0) }))
            #expect(players.allSatisfy { $0.personID == nil })
            #expect(shots.filter { $0.shooter != nil }.count == 1)
            #expect(shots.filter { $0.facingGoalkeeper != nil }.count == 1)
            #expect(teams[0].players.count == 3 && teams[0].sessions.count == 2)
            #expect(shots.allSatisfy { $0.targetCode == "inside.middle.center" && $0.outcomeCode == "goal" && $0.originX == 0.5 && $0.originY == 0.5 })
            try MatchHistoryUpgrade.run(in: context)
            let match = try #require(sessions.first { !$0.shots.isEmpty })
            let empty = try #require(sessions.first { $0.shots.isEmpty })
            let shooter = try #require(players.first { $0.number == 7 })
            let keeper = try #require(players.first { $0.number == 1 })
            shooterID = shooter.personID
            matchID = match.matchID
            #expect(Set(players.compactMap(\.personID)).count == 3)
            #expect(Set(sessions.compactMap(\.matchID)).count == 2)
            #expect(match.participants.count == 2)
            #expect(empty.participants.isEmpty)
            #expect(match.historyWasBackfilled == true && empty.historyWasBackfilled == true)
            #expect(match.shots.first { $0.shooter == nil && $0.facingGoalkeeper == nil }?.domainShot?.shooter == nil)
            let snapshotIDs = Set(match.participants.map(\.persistentModelID))
            try MatchHistoryUpgrade.run(in: context)
            #expect(Set(match.participants.map(\.persistentModelID)) == snapshotIDs)
            #expect(shooter.personID == shooterID && match.matchID == matchID)
            shooter.number = 9
            shooter.name = "Changed name"
            shooter.handednessCode = "right"
            shooter.archivedAt = .now
            keeper.archivedAt = .now
            let replacement = StoredPlayer(number: 7, name: "Different person", isGoalkeeper: false, handednessCode: nil)
            teams[0].players.append(replacement)
            context.insert(replacement)
            let later = StoredSession(date: match.date, kindCode: "video", rivalTeam: teams[0])
            teams[0].sessions.append(later)
            context.insert(later)
            let participant = MatchHistoryUpgrade.participant(for: replacement, in: later, context: context)
            let laterShot = StoredShot(date: match.date, attackingSideCode: "rival", originX: nil, originY: nil,
                                       isSevenMeters: true, targetCode: "inside.middle.center", outcomeCode: "saved",
                                       deliveryCode: nil, approachCode: nil, shooter: replacement, facingGoalkeeper: nil)
            laterShot.shooterSnapshot = participant
            later.shots.append(laterShot)
            context.insert(laterShot)
            replacement.number = 10
            replacement.name = "Later rename"
            try context.save()
        }
        do {
            let container = try open()
            let context = ModelContext(container)
            try MatchHistoryUpgrade.run(in: context)
            let players = try context.fetch(FetchDescriptor<StoredPlayer>())
            let sessions = try context.fetch(FetchDescriptor<StoredSession>())
            let shots = try context.fetch(FetchDescriptor<StoredShot>())
            #expect(players.count == 4 && sessions.count == 3 && shots.count == 4)
            let match = try #require(sessions.first { $0.matchID == matchID })
            let original = try #require(players.first { $0.personID == shooterID })
            #expect(original.number == 9 && original.archivedAt != nil)
            #expect(players.first { $0.number == 10 }?.personID != shooterID)
            let shot = try #require(match.shots.first { $0.shooter != nil })
            #expect(shot.shooter?.persistentModelID == original.persistentModelID)
            #expect(shot.domainShot?.shooter?.id == shooterID)
            #expect(shot.domainShot?.shooter?.number == 7)
            #expect(shot.domainShot?.shooter?.name == "Legacy Ana")
            #expect(shot.domainShot?.shooter?.handedness?.rawValue == "left")
            #expect(match.shots.first { $0.facingGoalkeeper != nil }?.domainShot?.facingGoalkeeper?.number == 1)
            #expect(match.participants.count == 2)
            let later = try #require(sessions.first { $0.shots.contains { $0.isSevenMeters } })
            #expect(later.matchID != matchID)
            #expect(later.historyWasBackfilled == false)
            #expect(later.shots.first?.domainShot?.shooter?.number == 7)
            #expect(later.shots.first?.domainShot?.shooter?.name == "Different person")
            #expect(later.shots.first?.domainShot?.shooter?.id != shooterID)
            #expect(later.shots.first?.shooter?.number == 10)
            #expect(later.participants.count == 1)
            #expect(sessions.first { $0.shots.isEmpty }?.participants.isEmpty == true)
        }
        try exerciseOwnAttributionAcrossReopen(at: storeURL)
    }
}

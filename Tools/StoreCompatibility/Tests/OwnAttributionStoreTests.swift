import Foundation
import SwiftData
import Testing
import KeepercentDomain
@testable import ProductionStore

struct OwnAttributionStoreTests {
    @Test @MainActor func mc4DiskUpgradePreservesAllCanonicalRowsAndUnknownOwnFacts() throws {
        let path = try #require(ProcessInfo.processInfo.environment["KEEPERCENT_COMPATIBILITY_DIRECTORY"])
        let directory = URL(fileURLWithPath: path, isDirectory: true)
        let url = directory.appendingPathComponent("mc4.store")
        let oldIDs = try JSONDecoder().decode([PersistentIdentifier].self,
                                              from: Data(contentsOf: directory.appendingPathComponent("mc4-identifiers.json")))
        let identities = try JSONDecoder().decode([UUID].self,
                                                  from: Data(contentsOf: directory.appendingPathComponent("mc4-identities.json")))
        let schema = Schema(KeepercentSchema.models)
        func open() throws -> ModelContainer {
            try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let canonicalIDs = try Set(oldIDs.map { try encoder.encode($0) })
        for _ in 0..<2 {
            let container = try open()
            let context = ModelContext(container)
            let teams = try context.fetch(FetchDescriptor<StoredRivalTeam>())
            let players = try context.fetch(FetchDescriptor<StoredPlayer>())
            let matches = try context.fetch(FetchDescriptor<StoredSession>())
            let shots = try context.fetch(FetchDescriptor<StoredShot>())
            let snapshots = try context.fetch(FetchDescriptor<StoredMatchParticipant>())
            #expect(teams.count == 1 && players.count == 3 && matches.count == 2 && shots.count == 3 && snapshots.count == 2)
            let current = teams.map(\.persistentModelID) + players.map(\.persistentModelID)
                + matches.map(\.persistentModelID) + shots.map(\.persistentModelID) + snapshots.map(\.persistentModelID)
            #expect(try Set(current.map { try encoder.encode($0) }) == canonicalIDs)
            #expect(Set(players.compactMap(\.personID)) == Set(identities.prefix(3)))
            #expect(Set(matches.compactMap(\.matchID)) == Set(identities.suffix(2)))
            #expect(try context.fetch(FetchDescriptor<StoredOwnTeam>()).isEmpty)
            #expect(matches.allSatisfy { $0.ownTeam == nil && $0.ownParticipants.isEmpty })
            #expect(shots.allSatisfy { $0.ownShooter == nil && $0.ownGoalkeeper == nil && $0.ownShooterSnapshot == nil && $0.ownGoalkeeperSnapshot == nil })
            #expect(shots.allSatisfy { $0.domainShot?.ownShooter == nil && $0.domainShot?.ownGoalkeeper == nil })
            let match = try #require(matches.first { !$0.shots.isEmpty })
            let rivalShot = try #require(match.shots.first { $0.shooter != nil })
            let ownShot = try #require(match.shots.first { $0.facingGoalkeeper != nil })
            #expect(teams[0].players.count == 3 && teams[0].sessions.count == 2)
            #expect(rivalShot.shooter?.personID == identities[0])
            #expect(ownShot.facingGoalkeeper?.personID == identities[1])
            #expect(rivalShot.shooterSnapshot?.personID == identities[0])
            #expect(ownShot.goalkeeperSnapshot?.personID == identities[1])
            #expect(rivalShot.domainShot?.shooter?.name == "MC4 Ana")
            #expect(shots.allSatisfy { $0.targetCode == "inside.middle.center" && $0.outcomeCode == "goal" && $0.originX == 0.5 && $0.originY == 0.8 })
            try MatchHistoryUpgrade.run(in: context)
            try MatchHistoryUpgrade.run(in: context)
            #expect(match.participants.count == 2 && match.ownParticipants.isEmpty)
            #expect(matches.allSatisfy { $0.historyWasBackfilled == false })
        }
        try exerciseOwnAttributionAcrossReopen(at: url)
    }
}

/// Shared actual-production round trip runs after both baseline upgrades.
/// No legacy attendance is inferred: this deliberately creates a later match.
@MainActor func exerciseOwnAttributionAcrossReopen(at url: URL) throws {
    let schema = Schema(KeepercentSchema.models)
    func open() throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
    }
    var originalID: UUID?
    var replacementID: UUID?
    var matchID: UUID?
    var replacementMatchID: UUID?
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    var snapshotIDs: Set<Data> = []
    let date = Date(timeIntervalSince1970: 1_700_000_100)
    do {
        let container = try open()
        let context = ModelContext(container)
        let rival = try #require(context.fetch(FetchDescriptor<StoredRivalTeam>()).first)
        let rivalShooter = try #require(rival.players.first { $0.archivedAt == nil && !$0.isGoalkeeper })
        let rivalKeeper = try #require(rival.players.first { $0.isGoalkeeper })
        let club = StoredOwnTeam(name: "Own club", createdAt: date)
        let player = StoredPlayer(number: rivalShooter.number, name: "Own Ana", isGoalkeeper: true, handednessCode: "left")
        originalID = player.personID
        club.players = [player]
        context.insert(club)
        let match = StoredSession(date: date, kindCode: "live", rivalTeam: rival)
        matchID = match.matchID
        match.ownTeam = club
        match.participants = [StoredMatchParticipant(rivalShooter.domainPlayer), StoredMatchParticipant(rivalKeeper.domainPlayer)]
        match.ownParticipants = [StoredMatchParticipant(player.domainPlayer)]
        rival.sessions.append(match)
        context.insert(match)
        // Equal shirt numbers on different sides are valid; each side validates independently.
        _ = try MatchRoster(players: match.participants.map(\.domainPlayer))
        _ = try MatchRoster(players: match.ownParticipants.map(\.domainPlayer))
        for side in AttackingSide.allCases {
            for outcome in ShotOutcome.allCases {
                let target: GoalTarget = switch outcome {
                case .goal, .saved: .inside(GoalZone(row: .middle, column: .center))
                case .post: .post(.crossbarCenter)
                case .out: .out(.wideRight, .middle)
                }
                let domain = try Shot.record(attackingSide: side, shooter: rivalShooter.domainPlayer,
                                             activeRivalGoalkeeper: rivalKeeper.domainPlayer,
                                             ownShooter: player.domainPlayer, ownGoalkeeper: player.domainPlayer,
                                             originPoint: nil, isSevenMeters: true, target: target, outcome: outcome, date: date)
                let stored = StoredShot(domain, shooter: side == .rival ? rivalShooter : nil,
                                        facingGoalkeeper: side == .own ? rivalKeeper : nil,
                                        ownShooter: player, ownGoalkeeper: player)
                stored.shooterSnapshot = side == .rival ? match.participants[0] : nil
                stored.goalkeeperSnapshot = side == .own ? match.participants[1] : nil
                stored.ownShooterSnapshot = side == .own ? match.ownParticipants[0] : nil
                stored.ownGoalkeeperSnapshot = side == .rival ? match.ownParticipants[0] : nil
                match.shots.append(stored)
                context.insert(stored)
            }
        }
        try context.save()
        #expect(player.ownShotsTaken.count == 4 && player.ownShotsFaced.count == 4)
        #expect(player.shotsTaken.isEmpty && player.shotsFaced.isEmpty)
        #expect(club.sessions.contains { $0.matchID == matchID })
        snapshotIDs = try Set(match.ownParticipants.map { try encoder.encode($0.persistentModelID) })
        player.number = 47
        player.name = "Renamed"
        player.isGoalkeeper = false
        player.handednessCode = "right"
        player.archivedAt = date
        let replacement = StoredPlayer(number: match.ownParticipants[0].number, name: "Different own person", isGoalkeeper: false, handednessCode: nil)
        replacementID = replacement.personID
        club.players.append(replacement)
        context.insert(replacement)
        let later = StoredSession(date: date, kindCode: "video", rivalTeam: rival)
        replacementMatchID = later.matchID
        later.ownTeam = club
        later.ownParticipants = [StoredMatchParticipant(replacement.domainPlayer)]
        later.participants = [StoredMatchParticipant(rivalKeeper.domainPlayer)]
        rival.sessions.append(later)
        context.insert(later)
        let replacementShot = try Shot.record(attackingSide: .own, shooter: nil,
                                              activeRivalGoalkeeper: rivalKeeper.domainPlayer, ownShooter: replacement.domainPlayer,
                                              originPoint: nil, isSevenMeters: true,
                                              target: .inside(GoalZone(row: .middle, column: .center)), outcome: .goal, date: date)
        let storedReplacementShot = StoredShot(replacementShot, shooter: nil, facingGoalkeeper: rivalKeeper, ownShooter: replacement)
        storedReplacementShot.goalkeeperSnapshot = later.participants[0]
        storedReplacementShot.ownShooterSnapshot = later.ownParticipants[0]
        later.shots.append(storedReplacementShot)
        context.insert(storedReplacementShot)
        // Another match legitimately assigns a different number to the same person.
        let renamedMatch = StoredSession(date: date, kindCode: "live", rivalTeam: rival)
        renamedMatch.ownTeam = club
        renamedMatch.ownParticipants = [StoredMatchParticipant(player.domainPlayer)]
        rival.sessions.append(renamedMatch)
        context.insert(renamedMatch)
        try context.save()
    }
    do {
        let container = try open()
        let context = ModelContext(container)
        try MatchHistoryUpgrade.run(in: context)
        let club = try #require(context.fetch(FetchDescriptor<StoredOwnTeam>()).first)
        #expect(club.players.count == 2 && club.sessions.count == 3)
        let original = try #require(club.players.first { $0.personID == originalID })
        let replacement = try #require(club.players.first { $0.personID == replacementID })
        #expect(original.personID != replacement.personID)
        #expect(original.number == 47 && original.name == "Renamed" && !original.isGoalkeeper && original.archivedAt != nil)
        #expect(original.ownShotsTaken.count == 4 && original.ownShotsFaced.count == 4)
        #expect(replacement.ownShotsTaken.count == 1 && replacement.ownShotsFaced.isEmpty)
        let matches = try context.fetch(FetchDescriptor<StoredSession>())
        let match = try #require(matches.first { $0.matchID == matchID })
        #expect(try Set(match.ownParticipants.map { try encoder.encode($0.persistentModelID) }) == snapshotIDs)
        #expect(match.ownTeam?.persistentModelID == club.persistentModelID)
        #expect(match.ownParticipants[0].name == "Own Ana" && match.ownParticipants[0].isGoalkeeper && match.ownParticipants[0].handednessCode == "left")
        #expect(match.shots.count == 8)
        for shot in match.shots {
            let domain = try #require(shot.domainShot)
            #expect(domain.isSevenMeters && domain.originPoint == nil)
            #expect(domain.outcome.rawValue == shot.outcomeCode && domain.target.code == shot.targetCode)
            let person = try #require(domain.attackingSide == .own ? domain.ownShooter : domain.ownGoalkeeper)
            #expect(person.id == originalID && person.number == match.ownParticipants[0].number && person.name == "Own Ana" && person.isGoalkeeper && person.handedness == .left)
            #expect((shot.attackingSideCode == "own" ? shot.ownShooter : shot.ownGoalkeeper)?.personID == originalID)
            #expect(shot.attackingSideCode == "own" ? shot.ownGoalkeeper == nil : shot.ownShooter == nil)
            #expect(ShotSummary(shot: domain, locale: Locale(identifier: "en")).text.contains("Own"))
        }
        let later = try #require(matches.first { $0.matchID == replacementMatchID })
        #expect(later.ownParticipants.first?.personID == replacementID)
        #expect(later.ownParticipants.first?.number == match.ownParticipants[0].number)
        #expect(later.ownParticipants.first?.name == "Different own person")
        #expect(later.shots.first?.ownShooter?.personID == replacementID)
        #expect(later.shots.first?.domainShot?.ownShooter?.id == replacementID)
        #expect(later.shots.first?.domainShot?.ownShooter?.id != originalID)
        // Existing legacy/MC4 matches remain unidentified after configuring a club.
        #expect(matches.filter { $0.ownTeam == nil }.allSatisfy { $0.ownParticipants.isEmpty && $0.shots.allSatisfy { $0.domainShot?.ownShooter == nil && $0.domainShot?.ownGoalkeeper == nil } })
        try MatchHistoryUpgrade.run(in: context)
        #expect(match.ownParticipants.count == 1 && match.shots.count == 8)
    }
}

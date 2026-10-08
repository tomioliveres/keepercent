import Foundation
import SwiftData
import KeepercentDomain

// Frozen model files are byte-for-byte copies from MC-4 starting HEAD
// dfb886e7150d387c4b4f47272b416908586b210a. No production models enter this process.
let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let schema = Schema([StoredRivalTeam.self, StoredPlayer.self, StoredSession.self, StoredShot.self, StoredMatchParticipant.self])
let configuration = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("mc4.store"))
let container = try ModelContainer(for: schema, configurations: [configuration])
let context = ModelContext(container)
let date = Date(timeIntervalSince1970: 1_700_000_000)
let shooter = StoredPlayer(number: 7, name: "MC4 Ana", isGoalkeeper: false, handednessCode: "left")
let keeper = StoredPlayer(number: 1, name: "MC4 Keeper", isGoalkeeper: true, handednessCode: "right")
let unused = StoredPlayer(number: 8, name: "Not selected", isGoalkeeper: false, handednessCode: nil)
let team = StoredRivalTeam(name: "MC4 team", createdAt: date, players: [shooter, keeper, unused])
let match = StoredSession(date: date, kindCode: "live", rivalTeam: team)
let empty = StoredSession(date: date, kindCode: "video", rivalTeam: team)
match.participants = [StoredMatchParticipant(shooter.domainPlayer), StoredMatchParticipant(keeper.domainPlayer)]
func shot(side: String, shooter: StoredPlayer? = nil, keeper: StoredPlayer? = nil) -> StoredShot {
    StoredShot(date: date, attackingSideCode: side, originX: 0.5, originY: 0.8,
               isSevenMeters: false, targetCode: "inside.middle.center", outcomeCode: "goal",
               deliveryCode: "jump", approachCode: "straight", shooter: shooter, facingGoalkeeper: keeper)
}
let attack = shot(side: "rival", shooter: shooter)
attack.shooterSnapshot = match.participants[0]
let defense = shot(side: "own", keeper: keeper)
defense.goalkeeperSnapshot = match.participants[1]
match.shots = [attack, defense, shot(side: "rival")]
team.sessions = [match, empty]
context.insert(team)
try context.save()
let ids = [team.persistentModelID, shooter.persistentModelID, keeper.persistentModelID, unused.persistentModelID,
           match.persistentModelID, empty.persistentModelID] + match.shots.map(\.persistentModelID) + match.participants.map(\.persistentModelID)
try JSONEncoder().encode(ids).write(to: directory.appendingPathComponent("mc4-identifiers.json"))
let identities = [shooter.personID!, keeper.personID!, unused.personID!, match.matchID!, empty.matchID!]
try JSONEncoder().encode(identities).write(to: directory.appendingPathComponent("mc4-identities.json"))
print("Created frozen MC4 disk schema: 1 team, 3 players, 2 matches, 3 shots, 2 snapshots")

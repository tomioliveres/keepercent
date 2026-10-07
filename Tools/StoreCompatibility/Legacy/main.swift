import Foundation
import SwiftData

// A separate executable creates the OLD disk schema. Production models must
// never enter this process, otherwise the test would only reopen a new store.
let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let schema = Schema([StoredRivalTeam.self, StoredPlayer.self, StoredSession.self, StoredShot.self])
let configuration = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("legacy.store"))
let container = try ModelContainer(for: schema, configurations: [configuration])
let context = ModelContext(container)
let shooter = StoredPlayer(number: 7, name: "Legacy Ana", isGoalkeeper: false, handednessCode: "left")
let keeper = StoredPlayer(number: 1, name: "Legacy Keeper", isGoalkeeper: true, handednessCode: "right")
let unused = StoredPlayer(number: 8, name: "Not evidenced", isGoalkeeper: false, handednessCode: nil)
let team = StoredRivalTeam(name: "Legacy team", players: [shooter, keeper, unused])
let date = Date(timeIntervalSince1970: 1_700_000_000)
let session = StoredSession(date: date, kindCode: "live", rivalTeam: team)
let empty = StoredSession(date: date, kindCode: "video", rivalTeam: team)
func shot(side: String, shooter: StoredPlayer? = nil, keeper: StoredPlayer? = nil) -> StoredShot {
    StoredShot(date: date, attackingSideCode: side, originX: 0.5, originY: 0.5,
               isSevenMeters: false, targetCode: "inside.middle.center", outcomeCode: "goal",
               deliveryCode: "jump", approachCode: "straight", shooter: shooter, facingGoalkeeper: keeper)
}
session.shots = [shot(side: "rival", shooter: shooter), shot(side: "own", keeper: keeper), shot(side: "rival")]
team.sessions = [session, empty]
context.insert(team)
try context.save()
// Keep the old persistent identifiers as evidence that opening does not replace
// the original rows with copies. Encodable SwiftData IDs include store identity.
let ids = [team.persistentModelID, shooter.persistentModelID, keeper.persistentModelID,
           unused.persistentModelID, session.persistentModelID, empty.persistentModelID] + session.shots.map(\.persistentModelID)
try JSONEncoder().encode(ids).write(to: directory.appendingPathComponent("identifiers.json"))
print("Created frozen baseline disk schema: 1 team, 3 players, 2 matches, 3 shots")

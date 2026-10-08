import Foundation
import SwiftData
import KeepercentDomain

/// A match owns a copy of the available roster facts, never a live projection.
@Model
final class StoredMatchParticipant {
    var personID: UUID
    var number: Int
    var name: String?
    var isGoalkeeper: Bool
    var handednessCode: String?

    init(_ player: Player) {
        precondition(player.id != nil, "Match participants require stable identity")
        personID = player.id!
        number = player.number
        name = player.name
        isGoalkeeper = player.isGoalkeeper
        handednessCode = player.handedness?.rawValue
    }

    var domainPlayer: Player {
        Player(id: personID, number: number, name: name, isGoalkeeper: isGoalkeeper, handednessCode: handednessCode)
    }
}

import Foundation
import SwiftData

// Frozen schema from 8f2c1b44b21a1cf3f1876ed656d4bbe971d592b3.
@Model
final class StoredPlayer {
    var number: Int
    var name: String?
    var isGoalkeeper: Bool
    var handednessCode: String?
    @Relationship(deleteRule: .nullify, inverse: \StoredShot.shooter)
    var shotsTaken: [StoredShot]
    @Relationship(deleteRule: .nullify, inverse: \StoredShot.facingGoalkeeper)
    var shotsFaced: [StoredShot]

    init(number: Int, name: String?, isGoalkeeper: Bool, handednessCode: String?, shotsTaken: [StoredShot] = [], shotsFaced: [StoredShot] = []) {
        self.number = number
        self.name = name
        self.isGoalkeeper = isGoalkeeper
        self.handednessCode = handednessCode
        self.shotsTaken = shotsTaken
        self.shotsFaced = shotsFaced
    }
}

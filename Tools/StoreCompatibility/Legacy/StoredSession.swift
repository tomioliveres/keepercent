import Foundation
import SwiftData

// Frozen schema from 8f2c1b44b21a1cf3f1876ed656d4bbe971d592b3.
@Model
final class StoredSession {
    var date: Date
    var kindCode: String
    var rivalTeam: StoredRivalTeam?
    @Relationship(deleteRule: .cascade)
    var shots: [StoredShot]

    init(date: Date, kindCode: String, rivalTeam: StoredRivalTeam?, shots: [StoredShot] = []) {
        self.date = date
        self.kindCode = kindCode
        self.rivalTeam = rivalTeam
        self.shots = shots
    }
}

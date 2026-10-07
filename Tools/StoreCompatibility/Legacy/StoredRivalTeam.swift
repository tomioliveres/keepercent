import Foundation
import SwiftData

// Frozen schema from 8f2c1b44b21a1cf3f1876ed656d4bbe971d592b3.
@Model
final class StoredRivalTeam {
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade)
    var players: [StoredPlayer]
    @Relationship(deleteRule: .nullify, inverse: \StoredSession.rivalTeam)
    var sessions: [StoredSession]

    init(name: String, createdAt: Date = .now, players: [StoredPlayer] = [], sessions: [StoredSession] = []) {
        self.name = name
        self.createdAt = createdAt
        self.players = players
        self.sessions = sessions
    }
}

import Foundation
import SwiftData

/// The optional configured own club. Roster edits preserve identities; matches
/// own independent participant snapshots, never projections of these rows.
@Model
final class StoredOwnTeam {
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .nullify)
    var players: [StoredPlayer] = []
    @Relationship(deleteRule: .nullify, inverse: \StoredSession.ownTeam)
    var sessions: [StoredSession] = []

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }
}

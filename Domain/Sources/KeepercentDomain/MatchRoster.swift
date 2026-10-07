import Foundation

public enum MatchRosterError: Error, Equatable, Sendable {
    case missingIdentity
    case duplicateIdentity(UUID)
}

/// Immutable participant values belonging to one match, not the current club roster.
public struct MatchRoster: Equatable, Sendable {
    public let players: [Player]

    public init(players: [Player]) throws {
        var identities = Set<UUID>()
        for player in players {
            guard let id = player.id else { throw MatchRosterError.missingIdentity }
            guard identities.insert(id).inserted else { throw MatchRosterError.duplicateIdentity(id) }
        }
        self.players = try Roster(players: players).players
    }

    public func player(id: UUID) -> Player? {
        players.first { $0.id == id }
    }
}

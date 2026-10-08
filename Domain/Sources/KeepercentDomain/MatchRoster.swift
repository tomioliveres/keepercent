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

/// Value-only editing state. Selection never discards a person's latest draft;
/// number and identity validation still belongs to MatchRoster at save time.
public struct MatchRosterDraft: Sendable {
    /// Initial display values and order stay fixed for this presentation.
    public let choices: [Player]
    public private(set) var selectedPlayers: [Player]
    private var drafts: [UUID: Player]
    private let lockedIDs: Set<UUID>

    public init(available: [Player], selected: [Player], lockedIDs: Set<UUID> = []) {
        var values: [UUID: Player] = [:]
        // Selected match snapshots win over today's reusable roster.
        for player in selected + available {
            guard let id = player.id, values[id] == nil else { continue }
            values[id] = player
        }
        choices = values.values.sorted {
            if $0.number != $1.number { return $0.number < $1.number }
            return ($0.id?.uuidString ?? "") < ($1.id?.uuidString ?? "")
        }
        drafts = values
        self.lockedIDs = lockedIDs
        // Retain malformed selected values so saving still reports validation
        // errors, rather than silently dropping nil or duplicate identities.
        selectedPlayers = selected
        for player in choices {
            if let id = player.id, lockedIDs.contains(id), !isSelected(id) {
                selectedPlayers.append(player)
            }
        }
    }

    public func player(id: UUID) -> Player? { drafts[id] }

    public func isSelected(_ id: UUID) -> Bool {
        selectedPlayers.contains { $0.id == id }
    }

    public mutating func setIncluded(_ included: Bool, for id: UUID) {
        guard let player = drafts[id], !lockedIDs.contains(id) else { return }
        if included {
            if !isSelected(id) { selectedPlayers.append(player) }
        } else {
            selectedPlayers.removeAll { $0.id == id }
        }
    }

    public mutating func setNumber(_ number: Int, for id: UUID) {
        guard let old = drafts[id], isSelected(id), !lockedIDs.contains(id) else { return }
        let edited = Player(id: id, number: number, name: old.name,
                            isGoalkeeper: old.isGoalkeeper, handedness: old.handedness)
        drafts[id] = edited
        selectedPlayers = selectedPlayers.map { $0.id == id ? edited : $0 }
    }
}

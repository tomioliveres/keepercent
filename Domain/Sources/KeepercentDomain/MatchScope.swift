import Foundation

public struct MatchShots: Equatable, Sendable {
    public let id: UUID
    public let shots: [Shot]

    public init(id: UUID, shots: [Shot]) {
        self.id = id
        self.shots = shots
    }
}

public enum MatchScope: Hashable, Sendable {
    case all
    case match(UUID)

    /// A missing selected match is empty, never permission to widen scope.
    public func shots(in matches: [MatchShots]) -> [Shot] {
        switch self {
        case .all: matches.flatMap(\.shots)
        case .match(let id): matches.first { $0.id == id }?.shots ?? []
        }
    }
}

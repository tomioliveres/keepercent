import Foundation
import KeepercentDomain

/// Container-side projection shared by scouting, person cards and exports.
enum ScopedMatchData {
    static func sessions(_ team: StoredRivalTeam, scope: MatchScope) -> [StoredSession] {
        switch scope {
        case .all: return team.sessions
        case .match(let id): return team.sessions.filter { $0.matchID == id }
        }
    }

    static func engine(_ team: StoredRivalTeam, scope: MatchScope) -> StatsEngine {
        let matches = team.sessions.compactMap { session -> MatchShots? in
            guard let id = session.matchID else { return nil }
            return MatchShots(id: id, shots: session.shots.compactMap(\.domainShot))
        }
        return StatsEngine(shots: scope.shots(in: matches))
    }

    static func player(_ id: UUID, team: StoredRivalTeam, scope: MatchScope) -> Player? {
        if case .match = scope {
            return sessions(team, scope: scope).flatMap(\.participants).first { $0.personID == id }?.domainPlayer
        }
        return team.players.first { $0.personID == id }?.domainPlayer
            ?? team.sessions.flatMap(\.participants).first { $0.personID == id }?.domainPlayer
    }

    static func options(_ team: StoredRivalTeam) -> [MatchScopeOption] {
        team.sessions.sorted {
            if $0.date != $1.date { return $0.date > $1.date }
            return ($0.matchID?.uuidString ?? "") < ($1.matchID?.uuidString ?? "")
        }.enumerated().compactMap { index, session in
            guard let id = session.matchID else { return nil }
            let date = session.date.formatted(date: .abbreviated, time: .omitted)
            let kind = session.kind.map(sessionKindLabel) ?? String(localized: "Unknown kind")
            return MatchScopeOption(id: id, label: String(localized: "\(date) · \(kind) · Match \(index + 1)"))
        }
    }

    static func label(_ team: StoredRivalTeam, scope: MatchScope) -> String {
        switch scope {
        case .all: return String(localized: "All matches")
        case .match(let id): return options(team).first { $0.id == id }?.label ?? String(localized: "Match unavailable")
        }
    }
}

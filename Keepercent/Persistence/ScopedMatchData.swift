import Foundation
import KeepercentDomain

/// Container-side projection shared by scouting, person cards and exports.
enum ScopedMatchData {
    static func sessions(_ team: StoredOwnTeam, scope: MatchScope) -> [StoredSession] {
        let selected: [StoredSession]
        switch scope {
        case .all: selected = team.sessions
        case .match(let id): selected = team.sessions.filter { $0.matchID == id }
        }
        return selected.sorted {
            if $0.date != $1.date { return $0.date > $1.date }
            return ($0.matchID?.uuidString ?? "") < ($1.matchID?.uuidString ?? "")
        }
    }

    static func engine(_ team: StoredOwnTeam, scope: MatchScope) -> StatsEngine {
        let matches = sessions(team, scope: .all).compactMap { session -> MatchShots? in
            guard let id = session.matchID else { return nil }
            let shots = session.shots.sorted {
                if $0.date != $1.date { return $0.date < $1.date }
                return String(describing: $0.persistentModelID) < String(describing: $1.persistentModelID)
            }.compactMap(\.domainShot)
            return MatchShots(id: id, shots: shots)
        }
        return StatsEngine(shots: scope.shots(in: matches))
    }

    static func player(_ id: UUID, team: StoredOwnTeam, scope: MatchScope) -> Player? {
        if case .match = scope {
            return sessions(team, scope: scope).flatMap(\.ownParticipants).first { $0.personID == id }?.domainPlayer
        }
        return people(team).first { $0.id == id }
    }

    /// Prefer today's roster header for All, retaining snapshot-only historical people.
    /// Sorted matches/people make fallback and number/name/UUID ties reproducible.
    static func people(_ team: StoredOwnTeam) -> [Player] {
        let snapshots = sessions(team, scope: .all).flatMap { session in
            session.ownParticipants.sorted { $0.personID.uuidString < $1.personID.uuidString }.map(\.domainPlayer)
        }
        var byID: [UUID: Player] = [:]
        for player in team.players.map(\.domainPlayer) + snapshots {
            if let id = player.id, byID[id] == nil { byID[id] = player }
        }
        return byID.values.sorted {
            if $0.number != $1.number { return $0.number < $1.number }
            func name(_ player: Player) -> String {
                (player.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            }
            if name($0) != name($1) { return name($0) < name($1) }
            return ($0.id?.uuidString ?? "") < ($1.id?.uuidString ?? "")
        }
    }

    static func options(_ team: StoredOwnTeam) -> [MatchScopeOption] {
        sessions(team, scope: .all).enumerated().compactMap { index, session in
            guard let id = session.matchID else { return nil }
            let opponent = session.rivalTeam?.name ?? String(localized: "Opponent unavailable")
            let date = session.date.formatted(date: .abbreviated, time: .omitted)
            let kind = session.kind.map(sessionKindLabel) ?? String(localized: "Unknown kind")
            let match = String(localized: "\(date) · \(kind) · Match \(index + 1)")
            return MatchScopeOption(id: id, label: "\(opponent) · \(match)")
        }
    }

    static func label(_ team: StoredOwnTeam, scope: MatchScope) -> String {
        switch scope {
        case .all: return String(localized: "All matches")
        case .match(let id): return options(team).first { $0.id == id }?.label ?? String(localized: "Match unavailable")
        }
    }

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

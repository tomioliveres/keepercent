import Foundation
import SwiftData
import KeepercentDomain

/// Explicit user-confirmed management actions. Domain validation precedes writes;
/// each action saves immediately or rolls back, like the existing roster editor.
@MainActor enum ScoutingDataActions {
    static func rename(_ team: StoredRivalTeam, to name: String, in context: ModelContext) throws {
        let validated = try RivalTeam(name: name)
        try save(in: context) { team.name = validated.name }
    }

    static func edit(_ match: StoredSession, kind: SessionKind, date: Date, in context: ModelContext) throws {
        let validated = try Session(kind: kind, matchDate: date, today: .now, calendar: .current)
        try save(in: context) {
            match.kindCode = validated.kind.rawValue
            match.date = validated.matchDate
        }
    }

    static func delete(_ match: StoredSession, in context: ModelContext) throws {
        // The existing relationship rules delete only this match's shots and
        // participant snapshots, never reusable club players or other matches.
        try save(in: context) { context.delete(match) }
    }

    static func delete(_ team: StoredRivalTeam, in context: ModelContext) throws {
        // Existing nullify rules retain sessions/shots and their snapshots;
        // only the reusable rival roster cascades with the team.
        try save(in: context) { context.delete(team) }
    }

    private static func save(in context: ModelContext, change: () -> Void) throws {
        do {
            change()
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}

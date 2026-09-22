// Roster models a rival team's set of players: it owns shirt-number
// uniqueness so a duplicate is unrepresentable, the same way `Shot.init`
// makes a 7 m throw with an `originPoint` unrepresentable by dropping the
// point rather than merely flagging the contradiction (see Shot.swift).
//
// See docs/mvp.md §6 for the roster editor screen this feeds, including the
// "+" tile that adds an unknown shirt number during live entry.

import Foundation

/// What can go wrong when mutating a `Roster`, with enough detail for a UI
/// message: which number was involved, and (for range and shot-count
/// failures) the bound that was violated.
public enum RosterError: Error, Equatable, Hashable, Sendable {
    /// A shirt number already used by another player in the roster.
    case duplicateNumber(Int)
    /// A shirt number outside `Roster.numberRange`, carried alongside that
    /// range so the UI can state the legal bounds without hardcoding them.
    case numberOutOfRange(number: Int, allowedRange: ClosedRange<Int>)
    /// Removal was blocked because the player already has recorded shots.
    /// `shotCount` is exactly what the caller passed to `remove`, so the UI
    /// can say "Ana (#7) has 12 recorded shots" rather than a generic
    /// refusal.
    case playerHasRecordedShots(number: Int, shotCount: Int)
    /// The operation named a shirt number no player in the roster has.
    case playerNotFound(number: Int)
}

/// Whether a `RivalTeam`'s name is usable. Kept separate from `RosterError`
/// because a team name is not a roster concern: the roster cannot see the
/// team it belongs to, and folding an unrelated failure into `RosterError`
/// would make every roster `switch` account for a case that operation could
/// never actually produce.
public enum RivalTeamError: Error, Equatable, Hashable, Sendable {
    /// The name was empty, or contained only whitespace.
    case blankName
}

/// A rival team's roster: the players a scout has entered for that team,
/// with shirt-number uniqueness as an invariant of the type rather than a
/// rule callers must remember to check.
///
/// Every mutating operation returns a new `Roster` and can fail. They throw
/// rather than return `Result<Roster, RosterError>` because every call site
/// is a single UI action (an "add player" button, a swipe-to-delete) invoked
/// straight from a SwiftUI action closure, never composed through
/// `map`/`flatMap` chains — `try`/`catch` reads as one line at each of those
/// call sites, while `Result` would add pattern-matching boilerplate and buy
/// nothing back for a type with no asynchronous or chained error path.
public struct Roster: Equatable, Hashable, Sendable {
    /// Legal handball shirt numbers, per IHF rules: 1 through 99 inclusive.
    public static let numberRange = 1...99

    private var playersByNumber: [Int: Player]

    /// An empty roster.
    public init() {
        self.playersByNumber = [:]
    }

    /// Builds a roster from players already held elsewhere — the container
    /// view's `StoredPlayer` rows, mapped through `.domainPlayer`.
    ///
    /// This exists so that fold never gets written inline in a SwiftUI view:
    /// the app target has no test target (see CLAUDE.md), so logic that
    /// lives there cannot be tested at all, while the same logic here is
    /// covered by `swift test`. It applies the very same range and
    /// uniqueness rules as `add(_:)` and throws on the first violation
    /// rather than dropping a row — a roster silently one player short
    /// misattributes every statistic derived from the player who vanished.
    public init(players: [Player]) throws {
        var roster = Roster()
        for player in players {
            roster = try roster.add(player)
        }
        self = roster
    }

    private init(playersByNumber: [Int: Player]) {
        self.playersByNumber = playersByNumber
    }

    /// All players, sorted by shirt number (numerically, not as strings —
    /// so #9 sorts before #10).
    public var players: [Player] {
        playersByNumber.values.sorted { $0.number < $1.number }
    }

    /// The player wearing `number`, if any.
    public func player(number: Int) -> Player? {
        playersByNumber[number]
    }

    /// Adds `player`. Rejected when `player.number` is already taken or
    /// falls outside `Roster.numberRange`; the roster is returned unchanged
    /// by throwing rather than by silently ignoring the call.
    public func add(_ player: Player) throws -> Roster {
        try validate(number: player.number, replacing: nil)
        var updated = playersByNumber
        updated[player.number] = player
        return Roster(playersByNumber: updated)
    }

    /// Adds an unknown shirt number: the "+" tile from docs/mvp.md §6, used
    /// during live entry when the scout sees a number on court with no name
    /// attached yet and must record it without leaving the shot-entry
    /// screen.
    ///
    /// This is deliberately NOT a distinct operation with its own
    /// validation: it is `add(_:)` given a `Player` built from `Player`'s
    /// own defaults (`name: nil`, `isGoalkeeper: false`, `handedness: nil`).
    /// A separate code path would have to re-implement the same uniqueness
    /// and range checks `add` already owns, and once decoded, a `Player`
    /// carries no flag recording which entry path produced it — a second
    /// implementation could only duplicate `add`'s rules, never add
    /// meaning of its own.
    public func addUnknown(number: Int) throws -> Roster {
        try add(Player(number: number))
    }

    /// Removes the player wearing `number`.
    ///
    /// The domain has no database to query, so the caller must state how
    /// many shots that player already has; removal is blocked whenever that
    /// count is nonzero, and the error carries both the number and the
    /// count so the UI can explain the refusal rather than merely report
    /// it. Removing a number no player in the roster wears is also an
    /// error, never a silent no-op.
    ///
    /// A negative `recordedShotCount` traps. It cannot come from counting
    /// anything, so it is a defect at the call site that builds the count,
    /// and letting it through would produce a refusal reading "has -1
    /// recorded shots" — a quiet wrong answer shown to the user instead of
    /// a loud failure at the boundary that created it. Same reasoning that
    /// put traps on `GoalGeometry.init` and `CourtGeometry.init` in T2.1
    /// and T2.2.
    public func remove(number: Int, recordedShotCount: Int) throws -> Roster {
        precondition(recordedShotCount >= 0, "Roster.remove recordedShotCount cannot be negative")
        guard playersByNumber[number] != nil else {
            throw RosterError.playerNotFound(number: number)
        }
        guard recordedShotCount == 0 else {
            throw RosterError.playerHasRecordedShots(number: number, shotCount: recordedShotCount)
        }
        var updated = playersByNumber
        updated.removeValue(forKey: number)
        return Roster(playersByNumber: updated)
    }

    /// Replaces the player currently wearing `number` with `updated`,
    /// which may itself carry a different shirt number to also renumber
    /// them in the same operation.
    ///
    /// `updated` is a whole replacement `Player`, not individual optional
    /// parameters per field: by the time a SwiftUI edit screen calls this,
    /// it already holds a complete edited draft (`@State var draft:
    /// Player`) bound to the form, so there is no "leave unchanged" case to
    /// express. A partial-update signature would need
    /// `Optional<Optional<T>>` per field to distinguish "leave as is" from
    /// "set to nil" (e.g. clearing `handedness`), which only pays off for a
    /// caller that edits fields independently — this one never does.
    ///
    /// Renumbering to a number already worn by a DIFFERENT player is
    /// rejected; "renumbering" to the player's own current number is not a
    /// conflict, since that number is about to be vacated by the very same
    /// update.
    public func update(number: Int, to updated: Player) throws -> Roster {
        guard playersByNumber[number] != nil else {
            throw RosterError.playerNotFound(number: number)
        }
        try validate(number: updated.number, replacing: number)
        var result = playersByNumber
        result.removeValue(forKey: number)
        result[updated.number] = updated
        return Roster(playersByNumber: result)
    }

    /// Validates that `number` is in range and free, except when it is the
    /// very number `replacing` names: that case is a self-update, not a
    /// conflict, because the number is being vacated by the same operation
    /// that claims it.
    private func validate(number: Int, replacing excludedNumber: Int?) throws {
        guard Roster.numberRange.contains(number) else {
            throw RosterError.numberOutOfRange(number: number, allowedRange: Roster.numberRange)
        }
        if playersByNumber[number] != nil, number != excludedNumber {
            throw RosterError.duplicateNumber(number)
        }
    }
}

/// A rival team: a validated name plus its roster.
public struct RivalTeam: Equatable, Hashable, Sendable {
    public let name: String
    public let roster: Roster

    /// Creates a team, rejecting a `name` that is empty or whitespace-only
    /// and storing it trimmed otherwise. This is the only name rule: the
    /// domain cannot see other teams, so it cannot and does not enforce
    /// uniqueness across them.
    public init(name: String, roster: Roster = Roster()) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw RivalTeamError.blankName
        }
        self.name = trimmed
        self.roster = roster
    }
}

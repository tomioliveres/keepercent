// Shot is the domain value type StatsEngine will consume: an assembled
// record of one recorded shot, plus the small pure-Swift value types that
// describe who took it, in what session context, and how it was thrown.
//
// Perspective: always the SHOOTER's point of view, consistent with
// GoalTarget, CourtZone and ShotClassification. See docs/mvp.md §5 for the
// full domain model this feeds.

import Foundation

/// Which hand a player shoots with.
///
/// The raw String value IS this enum's persistence code: stable, readable,
/// and round-trips through the compiler-synthesized `init?(rawValue:)`, so
/// no separate `code`/`init?(code:)` pair is needed (unlike `GoalTarget` and
/// `CourtZone`, which encode a compound value).
public enum Handedness: String, CaseIterable, Equatable, Hashable, Sendable {
    case left
    case right
}

/// A player on a rival team's roster: a shirt number, an optional name, and
/// whether they are the goalkeeper. See docs/mvp.md §5.
///
/// A value struct, not persisted directly: SwiftData stores its fields as
/// primitives (a raw string for `handedness`), and this struct is how the
/// domain and `StatsEngine` see a player.
public struct Player: Equatable, Hashable, Sendable {
    public let number: Int
    public let name: String?
    public let isGoalkeeper: Bool
    public let handedness: Handedness?

    public init(number: Int, name: String? = nil, isGoalkeeper: Bool = false, handedness: Handedness? = nil) {
        self.number = number
        self.name = name
        self.isGoalkeeper = isGoalkeeper
        self.handedness = handedness
    }
}

/// How a session was recorded: live from the bench, or from a paused video.
/// See docs/mvp.md §4 — the kind is metadata only, it never changes the
/// shot entry flow. Its raw String value is its persistence code (see
/// `Handedness`).
public enum SessionKind: String, CaseIterable, Equatable, Hashable, Sendable {
    case live
    case video
}

/// Which team is attacking on a given shot. See docs/mvp.md §5. Its raw
/// String value is its persistence code (see `Handedness`).
public enum AttackingSide: String, CaseIterable, Equatable, Hashable, Sendable {
    case rival
    case own
}

/// Whether the shooter was airborne or standing when they released the
/// shot. Its raw String value is its persistence code (see `Handedness`).
public enum ShotDelivery: String, CaseIterable, Equatable, Hashable, Sendable {
    case jump
    case standing
}

/// The lateral direction the shooter approached the release point from,
/// from the shooter's own perspective. Its raw String value is its
/// persistence code (see `Handedness`).
public enum ShotApproach: String, CaseIterable, Equatable, Hashable, Sendable {
    case fromLeft
    case fromRight
    case straight
}

/// One recorded shot: who took it, where from, where to, and how it ended.
/// See docs/mvp.md §5 for the full domain model.
///
/// `Shot` is assembled from its parts, not given its own persistence code:
/// every field is either a primitive (`Bool`, `Date`, the two `Double`s
/// behind `CourtPoint`) or one of the small enums here or in
/// GoalTarget.swift / CourtZone.swift, whose raw String value already IS
/// its persistence code.
public struct Shot: Equatable, Hashable, Sendable {
    /// Which team is attacking.
    public let attackingSide: AttackingSide
    /// The rival shooter; `nil` when the own team attacks.
    public let shooter: Player?
    /// The rival goalkeeper being faced; `nil` when the rival attacks.
    public let facingGoalkeeper: Player?
    /// The raw normalized tap the shot originated from, in the `0...1`
    /// court frame `CourtGeometry` derives a `CourtZone` from
    /// (docs/mvp.md §5.2). Always `nil` for a 7 m throw: the initializer
    /// drops any point passed alongside `isSevenMeters`, so persistence
    /// code reading this field directly can never resurrect a phantom
    /// origin that `origin` already ignores.
    public let originPoint: CourtPoint?
    /// Whether this was a 7 m throw, auto-detected from a tap on the 7 m
    /// mark. A 7 m throw always starts from the same spot, so it has no
    /// recorded origin point (docs/mvp.md §5).
    public let isSevenMeters: Bool
    /// Where the shot ended up relative to the goal frame.
    public let target: GoalTarget
    /// How the shot ended.
    public let outcome: ShotOutcome
    /// Whether the shooter was airborne or standing.
    public let delivery: ShotDelivery?
    /// The lateral approach direction.
    public let approach: ShotApproach?
    /// When the shot was recorded.
    public let date: Date

    public init(
        attackingSide: AttackingSide,
        shooter: Player? = nil,
        facingGoalkeeper: Player? = nil,
        originPoint: CourtPoint? = nil,
        isSevenMeters: Bool = false,
        target: GoalTarget,
        outcome: ShotOutcome,
        delivery: ShotDelivery? = nil,
        approach: ShotApproach? = nil,
        date: Date
    ) {
        self.attackingSide = attackingSide
        self.shooter = shooter
        self.facingGoalkeeper = facingGoalkeeper
        // A 7 m throw has no recorded origin (docs/mvp.md §5). Normalizing
        // here keeps the contradictory pair unrepresentable instead of
        // merely ignored by `origin`.
        self.originPoint = isSevenMeters ? nil : originPoint
        self.isSevenMeters = isSevenMeters
        self.target = target
        self.outcome = outcome
        self.delivery = delivery
        self.approach = approach
        self.date = date
    }
}

extension Shot {
    /// Where the shot originated, derived rather than stored:
    ///   - `.sevenMeters` for a 7 m throw, regardless of `originPoint` (a
    ///     7 m throw always starts from the same spot; see `ShotOrigin` in
    ///     CourtZone.swift).
    ///   - the zone `CourtGeometry` derives from `originPoint`, otherwise.
    ///   - `nil` when it is neither a 7 m throw nor has an `originPoint`.
    public var origin: ShotOrigin? {
        if isSevenMeters {
            return .sevenMeters
        }
        guard let originPoint else { return nil }
        return .zone(CourtGeometry.standard.zone(at: originPoint))
    }

    /// The shot's line (cross-shot / near-post / neutral), derived from
    /// `origin` and `target` via `ShotClassification.line`. `nil` when
    /// `origin` itself is `nil`.
    public var line: ShotLine? {
        guard let origin else { return nil }
        return ShotClassification.line(from: origin, to: target)
    }
}

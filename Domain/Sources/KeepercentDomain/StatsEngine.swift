// StatsEngine derives scouting statistics from a list of shots: filtered
// views, effectiveness and save-rate breakdowns, and distributions. It never
// decides what a number means — "strong" or "weak" is a judgement left to
// the presentation layer (T4.3/T4.4); this engine only counts.
//
// docs/mvp.md §5.3 asks for no minimum-sample rule, so every rate is
// reported as a `Tally` rather than a bare `Double`: a zone nobody has shot
// at yet must never read as a 0% weakness.
//
// `StatsEngine` takes plain domain structs, never a `ModelContext`, so every
// statistic here stays testable without a simulator (see CLAUDE.md).

import Foundation

/// A count of successes over attempts. `rate` is nil when nothing was
/// attempted, so "no data" can never read as 0%.
public struct Tally: Equatable, Hashable, Sendable {
    public let successes: Int
    public let attempts: Int

    public init(successes: Int, attempts: Int) {
        self.successes = successes
        self.attempts = attempts
    }

    public var rate: Double? {
        attempts == 0 ? nil : Double(successes) / Double(attempts)
    }
}

/// One origin paired with the goal zone it targeted, the key
/// `effectivenessByOriginTarget` groups by.
public struct OriginTargetPair: Equatable, Hashable, Sendable {
    public let origin: ShotOrigin
    public let zone: GoalZone

    public init(origin: ShotOrigin, zone: GoalZone) {
        self.origin = origin
        self.zone = zone
    }
}

/// Computes derived statistics over a list of shots. Filters return a
/// narrower engine so they chain (e.g. a shooter's shots from one origin),
/// and every other property reads the current `shots` list directly.
public struct StatsEngine: Equatable, Sendable {
    public let shots: [Shot]

    public init(shots: [Shot]) {
        self.shots = shots
    }
}

// MARK: - Filters

extension StatsEngine {
    /// The rival shooter's own shots, matched by shirt number: a container
    /// only ever feeds one rival team's shots, so the number alone is
    /// enough to identify them.
    public func shots(by shooterNumber: Int) -> StatsEngine {
        StatsEngine(shots: shots.filter {
            $0.attackingSide == .rival && $0.shooter?.number == shooterNumber
        })
    }

    /// The shots faced by one rival goalkeeper, matched by shirt number.
    public func shots(facing goalkeeperNumber: Int) -> StatsEngine {
        StatsEngine(shots: shots.filter {
            $0.attackingSide == .own && $0.facingGoalkeeper?.number == goalkeeperNumber
        })
    }

    /// The shots that originated from exactly this origin.
    public func shots(from origin: ShotOrigin) -> StatsEngine {
        StatsEngine(shots: shots.filter { $0.origin == origin })
    }

    /// Shots the rival team took.
    public var rivalShots: StatsEngine {
        StatsEngine(shots: shots.filter { $0.attackingSide == .rival })
    }

    /// Shots the own team took.
    public var ownShots: StatsEngine {
        StatsEngine(shots: shots.filter { $0.attackingSide == .own })
    }

    /// Shots from open play, excluding 7 m throws: 7 m is always shown
    /// apart from field play (docs/mvp.md §6).
    public var fieldShots: StatsEngine {
        StatsEngine(shots: shots.filter { !$0.isSevenMeters })
    }

    /// Only 7 m throws.
    public var sevenMeterShots: StatsEngine {
        StatsEngine(shots: shots.filter { $0.isSevenMeters })
    }
}

// MARK: - Outcome counts

extension StatsEngine {
    /// How many shots ended in each outcome. Every `ShotOutcome` case is
    /// present, zero-filled, so a chart never has to guess a missing case
    /// means zero.
    public var outcomeCounts: [ShotOutcome: Int] {
        var counts = Dictionary(uniqueKeysWithValues: ShotOutcome.allCases.map { ($0, 0) })
        for shot in shots {
            counts[shot.outcome, default: 0] += 1
        }
        return counts
    }

    /// Goals over every shot in this engine, regardless of origin.
    public var effectiveness: Tally {
        Tally(successes: shots.filter { $0.outcome == .goal }.count, attempts: shots.count)
    }
}

// MARK: - Effectiveness breakdowns

extension StatsEngine {
    /// Goals over attempts, grouped by origin. Only origins that actually
    /// have shots appear: a shot with no recorded origin is skipped here,
    /// though it still counts in `effectiveness`.
    public var effectivenessByOrigin: [ShotOrigin: Tally] {
        var counts: [ShotOrigin: (successes: Int, attempts: Int)] = [:]
        for shot in shots {
            guard let origin = shot.origin else { continue }
            counts[origin, default: (0, 0)].attempts += 1
            if shot.outcome == .goal {
                counts[origin, default: (0, 0)].successes += 1
            }
        }
        return counts.mapValues { Tally(successes: $0.successes, attempts: $0.attempts) }
    }

    /// Goals over shots aimed at each goal zone. Only `.inside` targets
    /// have a zone, so a post or a miss is skipped.
    public var effectivenessByGoalZone: [GoalZone: Tally] {
        var counts: [GoalZone: (successes: Int, attempts: Int)] = [:]
        for shot in shots {
            guard case .inside(let zone) = shot.target else { continue }
            counts[zone, default: (0, 0)].attempts += 1
            if shot.outcome == .goal {
                counts[zone, default: (0, 0)].successes += 1
            }
        }
        return counts.mapValues { Tally(successes: $0.successes, attempts: $0.attempts) }
    }

    /// Goals over attempts, grouped by origin and target zone together —
    /// the linked view T4.2 needs. Only shots with both a recorded origin
    /// and an `.inside` target contribute.
    public var effectivenessByOriginTarget: [OriginTargetPair: Tally] {
        var counts: [OriginTargetPair: (successes: Int, attempts: Int)] = [:]
        for shot in shots {
            guard let origin = shot.origin, case .inside(let zone) = shot.target else { continue }
            let pair = OriginTargetPair(origin: origin, zone: zone)
            counts[pair, default: (0, 0)].attempts += 1
            if shot.outcome == .goal {
                counts[pair, default: (0, 0)].successes += 1
            }
        }
        return counts.mapValues { Tally(successes: $0.successes, attempts: $0.attempts) }
    }
}

// MARK: - Goal-count rankings

/// One key (a `GoalZone` or a `ShotOrigin`) with its `Tally`, in the order
/// `topGoalZones`/`topOrigins` ranked it — so the shooter card (T4.3) can
/// show "4/5" next to the zone or origin it belongs to.
public struct RankedTally<Key: Equatable & Sendable>: Equatable, Sendable {
    public let key: Key
    public let tally: Tally

    public init(key: Key, tally: Tally) {
        self.key = key
        self.tally = tally
    }
}

extension StatsEngine {
    /// Ranks `tallies` by goal count, most dangerous first: a zone/origin
    /// with zero goals is not ranked at all (docs/mvp.md §5.3 defines no
    /// minimum-sample rule, so this only ever excludes on goals, never on
    /// sample size). Ties break on fewer attempts — the same goal count
    /// over fewer attempts is the higher rate — then on `canonicalOrder`
    /// (the key's own `CaseIterable`/declaration order), so the result is
    /// fully deterministic regardless of dictionary iteration order.
    private static func topRanked<Key: Hashable & Sendable>(
        from tallies: [Key: Tally],
        canonicalOrder: [Key],
        limit: Int
    ) -> [RankedTally<Key>] {
        let orderIndex = Dictionary(uniqueKeysWithValues: canonicalOrder.enumerated().map { ($1, $0) })
        return tallies
            .filter { $0.value.successes > 0 }
            .sorted { lhs, rhs in
                if lhs.value.successes != rhs.value.successes {
                    return lhs.value.successes > rhs.value.successes
                }
                if lhs.value.attempts != rhs.value.attempts {
                    return lhs.value.attempts < rhs.value.attempts
                }
                return (orderIndex[lhs.key] ?? 0) < (orderIndex[rhs.key] ?? 0)
            }
            .prefix(limit)
            .map { RankedTally(key: $0.key, tally: $0.value) }
    }

    /// The goal zones this engine's shots most often score in, ranked by
    /// goal count (not rate) up to `limit`. Reuses `effectivenessByGoalZone`
    /// rather than recomputing goals/attempts.
    public func topGoalZones(limit: Int) -> [RankedTally<GoalZone>] {
        Self.topRanked(from: effectivenessByGoalZone, canonicalOrder: GoalZone.allCases, limit: limit)
    }

    /// The origins this engine's shots most often score from, ranked by
    /// goal count (not rate) up to `limit`. Reuses `effectivenessByOrigin`
    /// rather than recomputing goals/attempts.
    public func topOrigins(limit: Int) -> [RankedTally<ShotOrigin>] {
        Self.topRanked(from: effectivenessByOrigin, canonicalOrder: ShotOrigin.allCases, limit: limit)
    }

    /// `saveRateByGoalZone`, inverted: what got past the goalkeeper rather
    /// than what she stopped. A goal conceded is exactly a shot on target
    /// that was not saved, so this walks no shots of its own — it derives
    /// straight from the tally `saveRateByGoalZone` already built.
    private var concededByGoalZone: [GoalZone: Tally] {
        saveRateByGoalZone.mapValues { Tally(successes: $0.attempts - $0.successes, attempts: $0.attempts) }
    }

    /// The goal zones this goalkeeper concedes from most often, ranked by
    /// goals CONCEDED (not rate) up to `limit` — the shooter card's mirror
    /// for the goalkeeper card (T4.4). Same exclusion/tie-break rules as
    /// `topGoalZones`: a zone with zero goals conceded is not ranked.
    public func weakGoalZones(limit: Int) -> [RankedTally<GoalZone>] {
        Self.topRanked(from: concededByGoalZone, canonicalOrder: GoalZone.allCases, limit: limit)
    }

    /// The goal zones this goalkeeper saves most often, ranked by SAVE
    /// count (not rate) up to `limit`. Reuses `saveRateByGoalZone` directly:
    /// its `successes` already ARE the save count this ranking wants.
    public func strongGoalZones(limit: Int) -> [RankedTally<GoalZone>] {
        Self.topRanked(from: saveRateByGoalZone, canonicalOrder: GoalZone.allCases, limit: limit)
    }
}

// MARK: - Save rate

extension StatsEngine {
    /// Saves over shots on target. "On target" is decided by the recorded
    /// outcome (`goal` or `saved`), not by the target the shot aimed at:
    /// decoded rows are not re-validated, so a `saved` shot always counts
    /// here even if its stored target looks inconsistent.
    public var saveRate: Tally {
        let onTarget = shots.filter { $0.outcome == .goal || $0.outcome == .saved }
        return Tally(successes: onTarget.filter { $0.outcome == .saved }.count, attempts: onTarget.count)
    }

    /// The same save rate, restricted to `.inside` targets and grouped by
    /// goal zone.
    public var saveRateByGoalZone: [GoalZone: Tally] {
        var counts: [GoalZone: (successes: Int, attempts: Int)] = [:]
        for shot in shots {
            guard case .inside(let zone) = shot.target,
                  shot.outcome == .goal || shot.outcome == .saved
            else { continue }
            counts[zone, default: (0, 0)].attempts += 1
            if shot.outcome == .saved {
                counts[zone, default: (0, 0)].successes += 1
            }
        }
        return counts.mapValues { Tally(successes: $0.successes, attempts: $0.attempts) }
    }

    /// The same save rate, grouped by origin instead of by goal zone. Only
    /// origins that actually have an on-target shot appear — the same
    /// "on target" test as `saveRate` (`goal` or `saved`, whatever the
    /// stored target says), not restricted to `.inside` targets: a save
    /// rate by origin is about where the shot came FROM, which every shot
    /// has regardless of where it ended up.
    public var saveRateByOrigin: [ShotOrigin: Tally] {
        var counts: [ShotOrigin: (successes: Int, attempts: Int)] = [:]
        for shot in shots {
            guard let origin = shot.origin,
                  shot.outcome == .goal || shot.outcome == .saved
            else { continue }
            counts[origin, default: (0, 0)].attempts += 1
            if shot.outcome == .saved {
                counts[origin, default: (0, 0)].successes += 1
            }
        }
        return counts.mapValues { Tally(successes: $0.successes, attempts: $0.attempts) }
    }
}

// MARK: - Reading

/// Which of the two cards a `StatsEngine` is feeding, so the linked view
/// (T4.2) can read the same tallies as either card without knowing their
/// names: the shooter card reads goals over attempts, the goalkeeper card
/// reads saves over shots on target.
public enum StatsReading: Sendable, CaseIterable {
    /// Goals over attempts — the shooter card.
    case effectiveness
    /// Saves over shots on target — the goalkeeper card.
    case saveRate
}

extension StatsEngine {
    /// The per-goal-zone tally for the given reading: `effectivenessByGoalZone`
    /// for `.effectiveness`, `saveRateByGoalZone` for `.saveRate`.
    public func goalZoneTallies(_ reading: StatsReading) -> [GoalZone: Tally] {
        switch reading {
        case .effectiveness: return effectivenessByGoalZone
        case .saveRate: return saveRateByGoalZone
        }
    }

    /// The per-origin tally for the given reading: `effectivenessByOrigin`
    /// for `.effectiveness`, `saveRateByOrigin` for `.saveRate`.
    public func originTallies(_ reading: StatsReading) -> [ShotOrigin: Tally] {
        switch reading {
        case .effectiveness: return effectivenessByOrigin
        case .saveRate: return saveRateByOrigin
        }
    }

    /// The engine the linked view's goal side should read from, given the
    /// court zone currently selected (T4.2): the shots from that one
    /// origin when something is selected, or every field shot when
    /// nothing is — 7 m always stays apart from field play (docs/mvp.md
    /// §6), so selecting `.sevenMeters` narrows to it explicitly rather
    /// than falling into `fieldShots`, which excludes it.
    public func goalEngine(forSelectedOrigin origin: ShotOrigin?) -> StatsEngine {
        guard let origin else { return fieldShots }
        return shots(from: origin)
    }
}

// MARK: - Distributions

extension StatsEngine {
    /// How many shots targeted each height band. Every `ShotHeight` case is
    /// zero-filled; a shot whose target has no height (per
    /// `ShotClassification.targetHeight(_:)`, e.g. any miss) is skipped.
    public var heightDistribution: [ShotHeight: Int] {
        var counts = Dictionary(uniqueKeysWithValues: ShotHeight.allCases.map { ($0, 0) })
        for shot in shots {
            guard let height = ShotClassification.targetHeight(shot.target) else { continue }
            counts[height, default: 0] += 1
        }
        return counts
    }

    /// How many shots fall into each `ShotLine` (cross-shot / near-post /
    /// neutral). Every case is zero-filled; a shot with no recorded origin
    /// has no line and is skipped. A 7 m throw has no lateral side, so it
    /// reads as `.neutral`: read this on `fieldShots` to keep 7 m apart.
    public var lineDistribution: [ShotLine: Int] {
        var counts = Dictionary(uniqueKeysWithValues: ShotLine.allCases.map { ($0, 0) })
        for shot in shots {
            guard let line = shot.line else { continue }
            counts[line, default: 0] += 1
        }
        return counts
    }
}

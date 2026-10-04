// ScoutingPatterns finds the tendencies a scout would write down — "shoots
// cross-court", "aims low when standing", "repeats a zone after scoring" —
// from a list of shots, with deterministic rules and named thresholds.
//
// Every pattern carries the counts behind it ("x of y"), never a bare rate,
// and a typed kind instead of prose: phrasing lives in `PatternPhraser`, and
// Foundation Models only ever rephrases those supplied sentences.
//
// Perspective: the SHOOTER's, like the rest of the domain. Field patterns
// read `fieldShots`; only the 7 m kinds read `sevenMeterShots`.

import Foundation

/// What a scouting pattern describes. Shooter kinds read a rival shooter's
/// (or the whole rival team's) shots; goalkeeper kinds read the shots a
/// goalkeeper faced.
public enum ScoutingPatternKind: Equatable, Hashable, Sendable {
    // MARK: Shooter

    /// Field shots split cross-court vs near post; neutral shots are left
    /// out of the sample.
    case line(ShotLine)
    /// The same split for the shots from one court sector by players of one
    /// hand (`nil` when the hand was not recorded).
    case lineFromSector(ShotLine, sector: CourtSector, hand: Handedness?)
    /// The height band most field shots aim at. Misses have no height.
    case height(ShotHeight)
    /// The goal side most field shots aim at. Misses are left out.
    case side(ShotSide)
    /// The height most shots with this delivery aim at.
    case deliveryHeight(ShotDelivery, ShotHeight)
    /// The side most shots with this delivery aim at.
    case deliverySide(ShotDelivery, ShotSide)
    /// The side most shots with this approach aim at.
    case approachSide(ShotApproach, ShotSide)
    /// The height most 7 m throws aim at.
    case sevenMeterHeight(ShotHeight)
    /// The side most 7 m throws aim at.
    case sevenMeterSide(ShotSide)
    /// The court zone most field shots come from.
    case origin(CourtZone)
    /// Conversion from near (tally) vs from far (contrast).
    case distance
    /// After a goal, how often the same shooter's next shot targets the
    /// same goal zone.
    case repeatAfterGoal

    // MARK: Goalkeeper

    /// The height most goals conceded went to.
    case concededHeight(ShotHeight)
    /// The side most goals conceded went to.
    case concededSide(ShotSide)
    /// Save rate on standing shots (tally) vs jump shots (contrast).
    case deliverySaves
    /// The 7 m save record.
    case sevenMeterSaves
}

/// One finding: what it is and the counts that support it.
public struct ScoutingPattern: Equatable, Hashable, Sendable {
    /// Fewest shots a single-sample tendency is read from.
    public static let minimumSample = 5
    /// Share a category needs among three or more options (height, side,
    /// origin zone) to count as dominant.
    public static let dominantShare = 0.6
    /// Share cross-court or near post needs in the two-way line split.
    public static let lineShare = 0.7
    /// Fewest shots on EACH side of a comparison (near vs far, standing vs
    /// jump).
    public static let comparisonMinimumSample = 4
    /// Smallest difference between two compared rates worth reporting.
    public static let comparisonGap = 0.3
    /// Fewest "goal, then next shot" pairs the repeat rule is read from.
    public static let minimumRepeatPairs = 4
    /// Share of those pairs that must repeat the same zone.
    public static let repeatShare = 0.5

    public let kind: ScoutingPatternKind
    /// "x of y": the shots matching the tendency over the sample it was
    /// read from. For a comparison, the first group's own rate.
    public let tally: Tally
    /// Goals over the matching shots, where that adds something.
    public let conversion: Tally?
    /// The second group of a comparison.
    public let contrast: Tally?

    public init(kind: ScoutingPatternKind, tally: Tally, conversion: Tally? = nil, contrast: Tally? = nil) {
        self.kind = kind
        self.tally = tally
        self.conversion = conversion
        self.contrast = contrast
    }

    /// How strongly the pattern leans, for ranking: the matching share
    /// for a tendency, the gap between the two rates for a comparison, and
    /// for the 7 m save record how far it leans either way (1 of 5 saved
    /// is as telling as 4 of 5).
    public var strength: Double {
        let rate = tally.rate ?? 0
        switch kind {
        case .distance, .deliverySaves:
            return abs(rate - (contrast?.rate ?? 0))
        case .sevenMeterSaves:
            return max(rate, 1 - rate)
        default:
            return rate
        }
    }
}

// MARK: - Finding patterns

extension StatsEngine {
    /// Every shooter-perspective pattern these shots support, strongest
    /// first. The caller caps how many it shows.
    public func shooterPatterns() -> [ScoutingPattern] {
        let field = fieldShots.shots
        let lineShots = field.filter { $0.line == .crossShot || $0.line == .nearPost }
        let lines: [ShotLine] = [.crossShot, .nearPost]
        var found: [ScoutingPattern?] = []

        found.append(Self.tendency(in: lineShots, among: lines, share: ScoutingPattern.lineShare, key: \.line) { .line($0) })
        found += Self.sectorLines(lineShots)
        found.append(Self.tendency(in: field, among: ShotHeight.allCases, key: Self.height) { .height($0) })
        found.append(Self.tendency(in: field, among: ShotSide.allCases, key: Self.side) { .side($0) })

        for delivery in ShotDelivery.allCases {
            let shots = field.filter { $0.delivery == delivery }
            found.append(Self.tendency(in: shots, among: ShotHeight.allCases, key: Self.height) { .deliveryHeight(delivery, $0) })
            found.append(Self.tendency(in: shots, among: ShotSide.allCases, key: Self.side) { .deliverySide(delivery, $0) })
        }
        for approach in ShotApproach.allCases {
            let shots = field.filter { $0.approach == approach }
            found.append(Self.tendency(in: shots, among: ShotSide.allCases, key: Self.side) { .approachSide(approach, $0) })
        }

        let sevenMeters = sevenMeterShots.shots
        found.append(Self.tendency(in: sevenMeters, among: ShotHeight.allCases, key: Self.height) { .sevenMeterHeight($0) })
        found.append(Self.tendency(in: sevenMeters, among: ShotSide.allCases, key: Self.side) { .sevenMeterSide($0) })

        found.append(Self.tendency(in: field, among: CourtZone.allCases, key: { Self.zone(of: $0) }) { .origin($0) })
        found.append(Self.distance(field))
        found.append(Self.repeatAfterGoal(field))
        return Self.ranked(found.compactMap { $0 })
    }

    /// Every goalkeeper-perspective pattern these faced shots support,
    /// strongest first. "Weak" means where the goals conceded went, read
    /// on shots on target only, like `saveRate`.
    public func goalkeeperPatterns() -> [ScoutingPattern] {
        let field = fieldShots.shots
        let conceded = field.filter { $0.outcome == .goal }
        var found: [ScoutingPattern?] = []

        // A conversion over goals conceded would always read "n of n".
        found.append(Self.tendency(in: conceded, among: ShotHeight.allCases, key: Self.height, withConversion: false) { .concededHeight($0) })
        found.append(Self.tendency(in: conceded, among: ShotSide.allCases, key: Self.side, withConversion: false) { .concededSide($0) })

        let standing = StatsEngine(shots: field.filter { $0.delivery == .standing }).saveRate
        let jump = StatsEngine(shots: field.filter { $0.delivery == .jump }).saveRate
        if Self.differ(standing, jump) {
            found.append(ScoutingPattern(kind: .deliverySaves, tally: standing, contrast: jump))
        }

        let sevenMeters = sevenMeterShots.saveRate
        if sevenMeters.attempts >= ScoutingPattern.minimumSample {
            found.append(ScoutingPattern(kind: .sevenMeterSaves, tally: sevenMeters))
        }
        return Self.ranked(found.compactMap { $0 })
    }

    /// Strongest first; ties go to the larger sample, then to the kind's
    /// fixed order, so the same shots always rank the same way.
    static func ranked(_ patterns: [ScoutingPattern]) -> [ScoutingPattern] {
        patterns.sorted { lhs, rhs in
            if lhs.strength != rhs.strength {
                return lhs.strength > rhs.strength
            }
            if lhs.tally.attempts != rhs.tally.attempts {
                return lhs.tally.attempts > rhs.tally.attempts
            }
            return lhs.kind.sortKey.lexicographicallyPrecedes(rhs.kind.sortKey)
        }
    }
}

// MARK: - Rules

private extension StatsEngine {
    /// Compares a share or gap with its threshold, tolerating the rounding
    /// that makes 0.7 - 0.4 come out as 0.29999999999999993.
    static func reaches(_ value: Double, _ threshold: Double) -> Bool {
        value + 1e-9 >= threshold
    }

    /// The category holding at least `share` of the shots that have one,
    /// read from at least `minimumSample` such shots. With a share above
    /// one half at most one category can qualify.
    static func tendency<Key: Equatable>(
        in shots: [Shot],
        among categories: [Key],
        share: Double = ScoutingPattern.dominantShare,
        key: (Shot) -> Key?,
        withConversion: Bool = true,
        kind: (Key) -> ScoutingPatternKind
    ) -> ScoutingPattern? {
        let sample = shots.filter { key($0) != nil }
        guard sample.count >= ScoutingPattern.minimumSample else { return nil }

        for category in categories {
            let matching = sample.filter { key($0) == category }
            guard reaches(Double(matching.count) / Double(sample.count), share) else { continue }
            return ScoutingPattern(
                kind: kind(category),
                tally: Tally(successes: matching.count, attempts: sample.count),
                conversion: withConversion ? StatsEngine(shots: matching).effectiveness : nil
            )
        }
        return nil
    }

    /// The line split read separately for each sector and shooting hand. A
    /// group holding every line shot is skipped: it would only repeat the
    /// overall `.line` pattern.
    static func sectorLines(_ lineShots: [Shot]) -> [ScoutingPattern?] {
        let hands: [Handedness?] = Handedness.allCases + [nil]
        var found: [ScoutingPattern?] = []
        for sector in CourtSector.allCases {
            for hand in hands {
                let group = lineShots.filter { zone(of: $0)?.sector == sector && $0.shooter?.handedness == hand }
                guard group.count < lineShots.count else { continue }
                found.append(tendency(in: group, among: [.crossShot, .nearPost], share: ScoutingPattern.lineShare, key: \.line) {
                    .lineFromSector($0, sector: sector, hand: hand)
                })
            }
        }
        return found
    }

    /// Near vs far conversion, when both have enough shots and the rates
    /// are far enough apart.
    static func distance(_ field: [Shot]) -> ScoutingPattern? {
        let near = StatsEngine(shots: field.filter { zone(of: $0)?.depth == .near }).effectiveness
        let far = StatsEngine(shots: field.filter { zone(of: $0)?.depth == .far }).effectiveness
        guard differ(near, far) else { return nil }
        return ScoutingPattern(kind: .distance, tally: near, contrast: far)
    }

    /// Whether two rates are both read from enough shots and differ by at
    /// least `comparisonGap`.
    static func differ(_ first: Tally, _ second: Tally) -> Bool {
        guard first.attempts >= ScoutingPattern.comparisonMinimumSample,
              second.attempts >= ScoutingPattern.comparisonMinimumSample,
              let firstRate = first.rate, let secondRate = second.rate
        else { return false }
        return reaches(abs(firstRate - secondRate), ScoutingPattern.comparisonGap)
    }

    /// Walks each shooter's shots in date order (recording order breaks a
    /// tie) and counts, after every goal, whether the next shot targeted
    /// the same goal zone. Shots with no recorded shooter are skipped.
    static func repeatAfterGoal(_ field: [Shot]) -> ScoutingPattern? {
        let byShooter = Dictionary(grouping: field.enumerated().filter { $0.element.shooter != nil }) {
            $0.element.shooter?.number
        }
        var pairs = 0
        var repeats = 0
        for shots in byShooter.values {
            let ordered = shots.sorted { ($0.element.date, $0.offset) < ($1.element.date, $1.offset) }.map(\.element)
            for (shot, next) in zip(ordered, ordered.dropFirst()) {
                guard shot.outcome == .goal, case .inside(let zone) = shot.target else { continue }
                pairs += 1
                if next.target == .inside(zone) {
                    repeats += 1
                }
            }
        }
        guard pairs >= ScoutingPattern.minimumRepeatPairs,
              reaches(Double(repeats) / Double(pairs), ScoutingPattern.repeatShare)
        else { return nil }
        return ScoutingPattern(kind: .repeatAfterGoal, tally: Tally(successes: repeats, attempts: pairs))
    }

    /// A shot's target height, `nil` for a miss — the same rule as
    /// `outcomesByHeight`.
    static func height(_ shot: Shot) -> ShotHeight? {
        shot.outcome == .out ? nil : ShotClassification.targetHeight(shot.target)
    }

    /// A shot's target side, `nil` for a miss — the same rule as
    /// `outcomesBySide`.
    static func side(_ shot: Shot) -> ShotSide? {
        if shot.outcome == .out { return nil }
        if case .out = shot.target { return nil }
        return ShotClassification.targetSide(shot.target)
    }

    /// A shot's court zone, `nil` for a 7 m throw or an unrecorded origin.
    static func zone(of shot: Shot) -> CourtZone? {
        guard case .zone(let zone) = shot.origin else { return nil }
        return zone
    }
}

// MARK: - Fixed order

extension ScoutingPatternKind {
    /// The kind's family first, then its values in their declared order:
    /// the last tie-break of `StatsEngine.ranked`.
    var sortKey: [Int] {
        switch self {
        case .line(let line): return [0, Self.index(line)]
        case .lineFromSector(let line, let sector, let hand):
            return [1, Self.index(sector), hand.map(Self.index) ?? Handedness.allCases.count, Self.index(line)]
        case .height(let height): return [2, Self.index(height)]
        case .side(let side): return [3, Self.index(side)]
        case .deliveryHeight(let delivery, let height): return [4, Self.index(delivery), Self.index(height)]
        case .deliverySide(let delivery, let side): return [5, Self.index(delivery), Self.index(side)]
        case .approachSide(let approach, let side): return [6, Self.index(approach), Self.index(side)]
        case .sevenMeterHeight(let height): return [7, Self.index(height)]
        case .sevenMeterSide(let side): return [8, Self.index(side)]
        case .origin(let zone): return [9, Self.index(zone)]
        case .distance: return [10]
        case .repeatAfterGoal: return [11]
        case .concededHeight(let height): return [12, Self.index(height)]
        case .concededSide(let side): return [13, Self.index(side)]
        case .deliverySaves: return [14]
        case .sevenMeterSaves: return [15]
        }
    }

    private static func index<Value: CaseIterable & Equatable>(_ value: Value) -> Int {
        Array(Value.allCases).firstIndex(of: value) ?? Value.allCases.count
    }
}

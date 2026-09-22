// ShotSummary builds the last-shot card's text, per docs/mvp.md §6's own
// example: "#7 · left back · crossbar center · POST". It stays free of any
// localization framework, since the display strings are short, fixed
// English phrases with no other consumer.
//
// Domain had no human-readable names for CourtZone / GoalTarget /
// ShotOutcome before this file (checked: none of them declare a
// `displayName`, `description` or similar), so this is new, small, pure
// code rather than a reuse of something that already existed.

/// The four display components of a recorded shot's summary card, and the
/// joined text docs/mvp.md §6 shows.
public struct ShotSummary: Equatable, Hashable, Sendable {
    /// Who the shot is attributed to. For a rival attack, the shooter's
    /// shirt number ("#7"). For an own-team attack, the active rival
    /// goalkeeper's number ("vs #12") — chosen because an own-team `Shot`
    /// carries no shooter at all (own players are not on any roster; see
    /// `Shot.record`), so the goalkeeper faced is the only person the card
    /// can name. "—" when the shot carries neither (a corrupt or
    /// decoded-away row).
    public let subject: String
    /// Where the shot originated: "7 m" for a seven-meter throw, else the
    /// origin zone's sector (e.g. "left back", matching docs/mvp.md §6's
    /// own example, which does not distinguish near/far). "—" when the
    /// shot has neither an origin point nor the 7 m flag.
    public let origin: String
    /// Where the shot ended up, e.g. "crossbar center", "top left",
    /// "wide right".
    public let target: String
    /// How the shot ended, uppercased (e.g. "POST", "GOAL").
    public let outcome: String

    public init(shot: Shot) {
        subject = Self.subject(for: shot)
        origin = Self.origin(for: shot)
        target = Self.target(for: shot.target)
        outcome = Self.outcome(for: shot.outcome)
    }

    /// The full card text, in docs/mvp.md §6's own order and separator.
    public var text: String {
        [subject, origin, target, outcome].joined(separator: " · ")
    }

    private static func subject(for shot: Shot) -> String {
        switch shot.attackingSide {
        case .rival:
            guard let shooter = shot.shooter else { return placeholder }
            return "#\(shooter.number)"
        case .own:
            guard let goalkeeper = shot.facingGoalkeeper else { return placeholder }
            return "vs #\(goalkeeper.number)"
        }
    }

    private static func origin(for shot: Shot) -> String {
        switch shot.origin {
        case .sevenMeters:
            return "7 m"
        case .zone(let zone):
            return sector(zone.sector)
        case nil:
            return placeholder
        }
    }

    private static func target(for target: GoalTarget) -> String {
        switch target {
        case .inside(let zone):
            return "\(row(zone.row)) \(column(zone.column))"
        case .post(let segment):
            return postSegment(segment)
        case .out(let direction):
            return missDirection(direction)
        }
    }

    // Every display string below is an explicit, exhaustive `switch` over
    // the enum's cases rather than a transform of `rawValue`: `rawValue` IS
    // the persistence code (see `GoalTarget.code`, `CourtZone.code`), so
    // display text must not be derived from it — renaming a label here must
    // never change what gets written to storage, and a new case must be a
    // compile error here, not a silently-humanized guess.

    private static func sector(_ sector: CourtSector) -> String {
        switch sector {
        case .leftWing: return "left wing"
        case .leftBack: return "left back"
        case .center: return "center"
        case .rightBack: return "right back"
        case .rightWing: return "right wing"
        }
    }

    private static func row(_ row: GoalRow) -> String {
        switch row {
        case .top: return "top"
        case .middle: return "middle"
        case .bottom: return "bottom"
        }
    }

    private static func column(_ column: GoalColumn) -> String {
        switch column {
        case .left: return "left"
        case .center: return "center"
        case .right: return "right"
        }
    }

    private static func postSegment(_ segment: PostSegment) -> String {
        switch segment {
        case .leftPostTop: return "left post top"
        case .leftPostMiddle: return "left post middle"
        case .leftPostBottom: return "left post bottom"
        case .crossbarLeft: return "crossbar left"
        case .crossbarCenter: return "crossbar center"
        case .crossbarRight: return "crossbar right"
        case .rightPostTop: return "right post top"
        case .rightPostMiddle: return "right post middle"
        case .rightPostBottom: return "right post bottom"
        }
    }

    private static func missDirection(_ direction: MissDirection) -> String {
        switch direction {
        case .wideLeft: return "wide left"
        case .wideRight: return "wide right"
        case .over: return "over"
        }
    }

    private static func outcome(for outcome: ShotOutcome) -> String {
        switch outcome {
        case .goal: return "GOAL"
        case .saved: return "SAVED"
        case .post: return "POST"
        case .out: return "OUT"
        }
    }

    private static let placeholder = "—"
}

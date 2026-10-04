import Foundation

// ShotSummary builds the last-shot card's text, per docs/mvp.md §6's own
// example: "#7 · left back · crossbar center · POST", in `locale`'s
// language ("#7 · lateral izquierdo · larguero centro · POSTE" in Spain).
// Zone and miss-part names come from DisplayNames.swift; the frame, miss
// and outcome labels below are this card's own.

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
    /// "wide right top" ("wide right" for a legacy miss with no third).
    public let target: String
    /// How the shot ended, uppercased (e.g. "POST", "GOAL").
    public let outcome: String

    public init(shot: Shot, locale: Locale = .current) {
        subject = Self.subject(for: shot, locale: locale)
        origin = Self.origin(for: shot, locale: locale)
        target = Self.target(for: shot.target, locale: locale)
        outcome = Self.outcome(for: shot.outcome, locale: locale)
    }

    /// The full card text, in docs/mvp.md §6's own order and separator.
    public var text: String {
        [subject, origin, target, outcome].joined(separator: " · ")
    }

    private static func subject(for shot: Shot, locale: Locale) -> String {
        switch shot.attackingSide {
        case .rival:
            guard let shooter = shot.shooter else { return placeholder }
            return "#\(shooter.number)"
        case .own:
            guard let goalkeeper = shot.facingGoalkeeper else { return placeholder }
            return String(domain: "vs #\(goalkeeper.number)", locale: locale)
        }
    }

    private static func origin(for shot: Shot, locale: Locale) -> String {
        switch shot.origin {
        case .sevenMeters:
            return "7 m"
        case .zone(let zone):
            return zone.sector.displayName(locale: locale)
        case nil:
            return placeholder
        }
    }

    private static func target(for target: GoalTarget, locale: Locale) -> String {
        switch target {
        case .inside(let zone):
            return zone.displayName(locale: locale)
        case .post(let segment):
            return postSegment(segment, locale: locale)
        case .out(let direction, let part?):
            return "\(missDirection(direction, locale: locale)) \(part.displayName(locale: locale))"
        case .out(let direction, nil):
            return missDirection(direction, locale: locale)
        }
    }

    // Every display string below is an explicit, exhaustive `switch` over
    // the enum's cases rather than a transform of `rawValue`: `rawValue` IS
    // the persistence code (see `GoalTarget.code`, `CourtZone.code`), so
    // display text must not be derived from it — renaming a label here must
    // never change what gets written to storage, and a new case must be a
    // compile error here, not a silently-humanized guess.

    private static func postSegment(_ segment: PostSegment, locale: Locale) -> String {
        switch segment {
        case .leftPostTop: String(domainKey: "frame.leftPostTop", defaultValue: "left post top", locale: locale)
        case .leftPostMiddle: String(domainKey: "frame.leftPostMiddle", defaultValue: "left post middle", locale: locale)
        case .leftPostBottom: String(domainKey: "frame.leftPostBottom", defaultValue: "left post bottom", locale: locale)
        case .crossbarLeft: String(domainKey: "frame.crossbarLeft", defaultValue: "crossbar left", locale: locale)
        case .crossbarCenter: String(domainKey: "frame.crossbarCenter", defaultValue: "crossbar center", locale: locale)
        case .crossbarRight: String(domainKey: "frame.crossbarRight", defaultValue: "crossbar right", locale: locale)
        case .rightPostTop: String(domainKey: "frame.rightPostTop", defaultValue: "right post top", locale: locale)
        case .rightPostMiddle: String(domainKey: "frame.rightPostMiddle", defaultValue: "right post middle", locale: locale)
        case .rightPostBottom: String(domainKey: "frame.rightPostBottom", defaultValue: "right post bottom", locale: locale)
        }
    }

    private static func missDirection(_ direction: MissDirection, locale: Locale) -> String {
        switch direction {
        case .wideLeft: String(domainKey: "miss.wideLeft", defaultValue: "wide left", locale: locale)
        case .wideRight: String(domainKey: "miss.wideRight", defaultValue: "wide right", locale: locale)
        case .over: String(domainKey: "miss.over", defaultValue: "over", locale: locale)
        }
    }

    private static func outcome(for outcome: ShotOutcome, locale: Locale) -> String {
        switch outcome {
        case .goal: String(domainKey: "outcome.goal", defaultValue: "GOAL", locale: locale)
        case .saved: String(domainKey: "outcome.saved", defaultValue: "SAVED", locale: locale)
        case .post: String(domainKey: "outcome.post", defaultValue: "POST", locale: locale)
        case .out: String(domainKey: "outcome.out", defaultValue: "OUT", locale: locale)
        }
    }

    private static let placeholder = "—"
}

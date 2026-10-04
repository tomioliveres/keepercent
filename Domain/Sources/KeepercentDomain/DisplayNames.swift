import Foundation

// Short, human-readable names for the court and goal enums, in `locale`'s
// language. They live in Domain because both Domain's own phrasing
// (`PatternPhraser`, `TemplateInsightWriter`, `ShotSummary`) and the app's
// views show them, and a scout must never see two names for one zone.
//
// Every name is an explicit `switch`, never a transform of `rawValue`:
// `rawValue` is the persistence code, so renaming a label must not change
// what is stored, and a new case must be a compile error here.

extension CourtSector {
    /// e.g. "left back".
    public func displayName(locale: Locale = .current) -> String {
        switch self {
        case .leftWing: String(domainKey: "sector.leftWing", defaultValue: "left wing", locale: locale)
        case .leftBack: String(domainKey: "sector.leftBack", defaultValue: "left back", locale: locale)
        case .center: String(domainKey: "sector.center", defaultValue: "center", locale: locale)
        case .rightBack: String(domainKey: "sector.rightBack", defaultValue: "right back", locale: locale)
        case .rightWing: String(domainKey: "sector.rightWing", defaultValue: "right wing", locale: locale)
        }
    }
}

extension CourtDepth {
    /// "near" or "far".
    public func displayName(locale: Locale = .current) -> String {
        switch self {
        case .near: String(domainKey: "depth.near", defaultValue: "near", locale: locale)
        case .far: String(domainKey: "depth.far", defaultValue: "far", locale: locale)
        }
    }
}

extension GoalRow {
    /// "top", "middle" or "bottom".
    public func displayName(locale: Locale = .current) -> String {
        switch self {
        case .top: String(domainKey: "position.top", defaultValue: "top", locale: locale)
        case .middle: String(domainKey: "position.middle", defaultValue: "middle", locale: locale)
        case .bottom: String(domainKey: "position.bottom", defaultValue: "bottom", locale: locale)
        }
    }
}

extension GoalColumn {
    /// "left", "center" or "right".
    public func displayName(locale: Locale = .current) -> String {
        switch self {
        case .left: String(domainKey: "position.left", defaultValue: "left", locale: locale)
        case .center: String(domainKey: "position.center", defaultValue: "center", locale: locale)
        case .right: String(domainKey: "position.right", defaultValue: "right", locale: locale)
        }
    }
}

extension MissPart {
    /// The third a miss went to, e.g. "top" or "center" — the same words a
    /// goal row or column uses.
    public func displayName(locale: Locale = .current) -> String {
        switch self {
        case .top: GoalRow.top.displayName(locale: locale)
        case .middle: GoalRow.middle.displayName(locale: locale)
        case .bottom: GoalRow.bottom.displayName(locale: locale)
        case .left: GoalColumn.left.displayName(locale: locale)
        case .center: GoalColumn.center.displayName(locale: locale)
        case .right: GoalColumn.right.displayName(locale: locale)
        }
    }
}

extension GoalZone {
    /// Row then column, e.g. "top left" ("arriba izquierda").
    public func displayName(locale: Locale = .current) -> String {
        "\(row.displayName(locale: locale)) \(column.displayName(locale: locale))"
    }
}

extension ShotOrigin {
    /// "7 m", or a court zone as "left wing · near".
    public func displayName(locale: Locale = .current) -> String {
        switch self {
        case .sevenMeters:
            "7 m"
        case .zone(let zone):
            "\(zone.sector.displayName(locale: locale)) · \(zone.depth.displayName(locale: locale))"
        }
    }
}

extension ShotHeight {
    /// "top", "middle" or "bottom": the goal row's own words.
    public func displayName(locale: Locale = .current) -> String {
        switch self {
        case .top: GoalRow.top.displayName(locale: locale)
        case .middle: GoalRow.middle.displayName(locale: locale)
        case .bottom: GoalRow.bottom.displayName(locale: locale)
        }
    }
}

extension ShotSide {
    /// "left", "center" or "right": the goal column's own words.
    public func displayName(locale: Locale = .current) -> String {
        switch self {
        case .left: GoalColumn.left.displayName(locale: locale)
        case .center: GoalColumn.center.displayName(locale: locale)
        case .right: GoalColumn.right.displayName(locale: locale)
        }
    }
}

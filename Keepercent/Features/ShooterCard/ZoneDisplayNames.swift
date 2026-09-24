// Human-readable names for GoalZone and ShotOrigin, used by the shooter
// card's "Where they score" rankings (T4.3). `CourtSector`/`CourtDepth`'s
// own display names already live on `LinkedZonesView.swift` (T4.2) — made
// non-`private` there so this file can reuse them instead of a second,
// possibly-drifting copy. `GoalRow`/`GoalColumn` had no display names yet,
// so they are added here.

import KeepercentDomain

extension GoalRow {
    var displayName: String {
        switch self {
        case .top: return "top"
        case .middle: return "middle"
        case .bottom: return "bottom"
        }
    }
}

extension GoalColumn {
    var displayName: String {
        switch self {
        case .left: return "left"
        case .center: return "center"
        case .right: return "right"
        }
    }
}

extension GoalZone {
    /// e.g. "top left", "middle center".
    var displayName: String {
        "\(row.displayName) \(column.displayName)"
    }
}

extension ShotOrigin {
    /// e.g. "7 m", "left wing · near" — matches `LinkedZonesView`'s own
    /// `filterDescription` wording for a selected court zone.
    var displayName: String {
        switch self {
        case .sevenMeters:
            return "7 m"
        case .zone(let zone):
            return "\(zone.sector.displayName) · \(zone.depth.displayName)"
        }
    }
}

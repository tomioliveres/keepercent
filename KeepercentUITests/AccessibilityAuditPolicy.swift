import XCTest

/// Only invisible drawing representations can produce these known false positives.
/// Hit regions, Dynamic Type, missing labels and traits are never suppressed.
@MainActor
enum AccessibilityAuditPolicy {
    static func ignores(_ issue: XCUIAccessibilityAuditIssue) -> Bool {
        guard issue.auditType == .textClipped || issue.auditType == .contrast,
              let identifier = issue.element?.identifier else { return false }
        return drawingIdentifiers.contains(identifier)
    }

    private static let drawingIdentifiers: Set<String> = {
        let rows = ["top", "middle", "bottom"]
        let columns = ["left", "center", "right"]
        let inside = rows.flatMap { row in columns.map { "inside.\(row).\($0)" } }
        let posts = ["leftPostTop", "leftPostMiddle", "leftPostBottom", "crossbarLeft", "crossbarCenter", "crossbarRight",
                     "rightPostTop", "rightPostMiddle", "rightPostBottom"].map { "post.\($0)" }
        let misses = columns.map { "out.over.\($0)" }
            + rows.flatMap { row in ["out.wideLeft.\(row)", "out.wideRight.\(row)"] }
        let goal = ["goal.entry", "goal.linked"].flatMap { scope in (inside + posts + misses).map { "\(scope).\($0)" } }
        let zones = ["leftWing.near", "leftBack.near", "center.near", "rightBack.near", "rightWing.near",
                     "leftBack.far", "center.far", "rightBack.far"].map { "zone.\($0)" } + ["sevenMeters"]
        let court = ["court.entry", "court.linked"].flatMap { scope in zones.map { "\(scope).\($0)" } }
        return Set(goal + court)
    }()
}

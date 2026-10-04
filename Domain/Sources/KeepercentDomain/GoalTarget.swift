// GoalTarget models where a shot ends up relative to the goal frame.
//
// Perspective: always the SHOOTER's point of view (facing the goal and the
// goalkeeper). The shooter's left is the goalkeeper's right. See docs/mvp.md
// §5.1.

/// A row in the 3x3 inside-the-frame grid, from the shooter's perspective.
public enum GoalRow: String, CaseIterable, Equatable, Hashable, Sendable {
    case top
    case middle
    case bottom
}

/// A column in the 3x3 inside-the-frame grid, from the shooter's perspective
/// (the shooter's left is the goalkeeper's right).
public enum GoalColumn: String, CaseIterable, Equatable, Hashable, Sendable {
    case left
    case center
    case right
}

/// One cell of the 3x3 grid inside the goal frame.
public struct GoalZone: Equatable, Hashable, Sendable {
    public let row: GoalRow
    public let column: GoalColumn

    public init(row: GoalRow, column: GoalColumn) {
        self.row = row
        self.column = column
    }
}

extension GoalZone: CaseIterable {
    /// All 9 zones of the 3x3 grid, derived from `GoalRow` and `GoalColumn`
    /// so this list cannot drift from those two enums.
    public static var allCases: [GoalZone] {
        GoalRow.allCases.flatMap { row in
            GoalColumn.allCases.map { column in GoalZone(row: row, column: column) }
        }
    }
}

/// A segment of the goal frame itself (post or crossbar), from the shooter's
/// perspective.
public enum PostSegment: String, CaseIterable, Equatable, Hashable, Sendable {
    case leftPostTop
    case leftPostMiddle
    case leftPostBottom
    case crossbarLeft
    case crossbarCenter
    case crossbarRight
    case rightPostTop
    case rightPostMiddle
    case rightPostBottom
}

/// A shot that misses the frame entirely, from the shooter's perspective.
public enum MissDirection: String, CaseIterable, Equatable, Hashable, Sendable {
    case wideLeft
    case wideRight
    case over

    /// The thirds this direction splits into: a wide miss by the mouth's
    /// height, an over miss by the mouth's width. These are the only
    /// valid (direction, part) pairs.
    public var parts: [MissPart] {
        switch self {
        case .wideLeft, .wideRight: return [.top, .middle, .bottom]
        case .over: return [.left, .center, .right]
        }
    }
}

/// Which third of its `MissDirection` a miss went to, from the shooter's
/// perspective. Wide left/right use `top`/`middle`/`bottom` (the mouth's
/// height thirds); over uses `left`/`center`/`right` (the mouth's width
/// thirds). See `MissDirection.parts`.
public enum MissPart: String, CaseIterable, Equatable, Hashable, Sendable {
    case top
    case middle
    case bottom
    case left
    case center
    case right
}

/// The outcome of a recorded shot.
public enum ShotOutcome: String, CaseIterable, Equatable, Hashable, Sendable {
    case goal
    case saved
    case post
    case out
}

/// Where a shot ends up: inside the frame, on the frame itself, or missing it.
///
/// A tap on the frame or outside the frame fully resolves the outcome
/// (`.post` / `.out`); a tap inside the frame still needs a goal/saved
/// answer. See `impliedOutcome`.
public enum GoalTarget: Equatable, Hashable, Sendable {
    case inside(GoalZone)
    case post(PostSegment)
    /// A miss and the third it went to. The part is `nil` only for a shot
    /// recorded before misses were split into thirds: that third is
    /// unknown and is never guessed.
    case out(MissDirection, MissPart?)
}

extension GoalTarget {
    /// Persistence code format (stable, readable, round-trips losslessly):
    ///   - inside: "inside.<row>.<column>"   e.g. "inside.top.left"
    ///   - post:   "post.<segment>"          e.g. "post.crossbarCenter"
    ///   - out:    "out.<direction>.<part>"  e.g. "out.wideLeft.top"
    ///   - legacy out, third unknown: "out.<direction>"  e.g. "out.wideLeft"
    ///
    /// SwiftData stores this primitive string; the domain exposes the rich
    /// enum. An unknown or malformed code decodes to `nil`.
    public var code: String {
        switch self {
        case .inside(let zone):
            return "inside.\(zone.row.rawValue).\(zone.column.rawValue)"
        case .post(let segment):
            return "post.\(segment.rawValue)"
        case .out(let direction, let part?):
            return "out.\(direction.rawValue).\(part.rawValue)"
        case .out(let direction, nil):
            return "out.\(direction.rawValue)"
        }
    }

    public init?(code: String) {
        let parts = code.split(separator: ".", omittingEmptySubsequences: false).map(String.init)

        switch parts.first {
        case "inside":
            guard parts.count == 3,
                  let row = GoalRow(rawValue: parts[1]),
                  let column = GoalColumn(rawValue: parts[2])
            else { return nil }
            self = .inside(GoalZone(row: row, column: column))

        case "post":
            guard parts.count == 2,
                  let segment = PostSegment(rawValue: parts[1])
            else { return nil }
            self = .post(segment)

        case "out":
            guard parts.count == 2 || parts.count == 3,
                  let direction = MissDirection(rawValue: parts[1])
            else { return nil }
            if parts.count == 2 {
                self = .out(direction, nil)
            } else {
                guard let part = MissPart(rawValue: parts[2]),
                      direction.parts.contains(part)
                else { return nil }
                self = .out(direction, part)
            }

        default:
            return nil
        }
    }

    /// The outcome implied by the target alone: a post or a miss fully
    /// resolves the outcome in one tap. An inside target implies nothing —
    /// the user is still asked "goal or saved".
    public var impliedOutcome: ShotOutcome? {
        switch self {
        case .inside:
            return nil
        case .post:
            return .post
        case .out:
            return .out
        }
    }
}

extension GoalTarget: CaseIterable {
    /// Every target a tap can produce, derived from the underlying
    /// CaseIterable enums so this list cannot drift as cases are added.
    /// Misses are the nine concrete (direction, part) pairs; a legacy miss
    /// with no third is decodable but never tappable, so it is not listed.
    public static var allCases: [GoalTarget] {
        GoalZone.allCases.map(GoalTarget.inside)
            + PostSegment.allCases.map(GoalTarget.post)
            + MissDirection.allCases.flatMap { direction in
                direction.parts.map { GoalTarget.out(direction, $0) }
            }
    }
}

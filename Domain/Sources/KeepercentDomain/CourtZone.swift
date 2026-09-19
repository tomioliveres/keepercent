// CourtZone models where a shot originates on the court.
//
// Perspective: always the SHOOTER's point of view (facing the goal). The
// court is drawn with the goal at the top and the shooter below looking up
// at it, so the shooter's left is screen-left, and the shooter's left is
// the goalkeeper's right — the same convention as GoalTarget. See
// docs/mvp.md §5.2.

/// A radial sector fanning out from the goal, from the shooter's
/// perspective (the shooter's left is the goalkeeper's right).
public enum CourtSector: String, CaseIterable, Equatable, Hashable, Sendable {
    case leftWing
    case leftBack
    case center
    case rightBack
    case rightWing
}

/// A depth band split by the 9 m line.
public enum CourtDepth: String, CaseIterable, Equatable, Hashable, Sendable {
    /// Between the goal and the 9 m line.
    case near
    /// Beyond the 9 m line.
    case far
}

/// One of the 10 court zones (5 sectors x 2 depths) a shot can originate
/// from.
public struct CourtZone: Equatable, Hashable, Sendable {
    public let sector: CourtSector
    public let depth: CourtDepth

    public init(sector: CourtSector, depth: CourtDepth) {
        self.sector = sector
        self.depth = depth
    }
}

extension CourtZone: CaseIterable {
    /// All 10 zones, derived from `CourtSector` and `CourtDepth` so this
    /// list cannot drift from those two enums.
    public static var allCases: [CourtZone] {
        CourtSector.allCases.flatMap { sector in
            CourtDepth.allCases.map { depth in CourtZone(sector: sector, depth: depth) }
        }
    }
}

extension CourtZone {
    /// Persistence code format (stable, readable, round-trips losslessly):
    /// "<sector>.<depth>", e.g. "leftWing.near", "center.far".
    ///
    /// SwiftData stores this primitive string; the domain exposes the rich
    /// struct. An unknown or malformed code decodes to `nil`.
    public var code: String {
        "\(sector.rawValue).\(depth.rawValue)"
    }

    public init?(code: String) {
        let parts = code.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 2,
              let sector = CourtSector(rawValue: parts[0]),
              let depth = CourtDepth(rawValue: parts[1])
        else { return nil }
        self.sector = sector
        self.depth = depth
    }
}

/// Where a shot originates: a court zone, or the 7 m mark.
///
/// A 7 m throw has no court origin of its own — the shooter always throws
/// from the same spot, so it is reported separately in stats rather than
/// mapped onto a `CourtZone`. See docs/mvp.md §5.2.
public enum ShotOrigin: Equatable, Hashable, Sendable {
    case zone(CourtZone)
    case sevenMeters
}

extension ShotOrigin {
    /// Persistence code format (stable, readable, round-trips losslessly):
    ///   - zone:        "zone.<sector>.<depth>"   e.g. "zone.leftWing.near"
    ///   - sevenMeters: "sevenMeters"
    ///
    /// An unknown or malformed code decodes to `nil`.
    public var code: String {
        switch self {
        case .zone(let zone):
            return "zone.\(zone.code)"
        case .sevenMeters:
            return "sevenMeters"
        }
    }

    public init?(code: String) {
        if code == "sevenMeters" {
            self = .sevenMeters
            return
        }

        let zonePrefix = "zone."
        guard code.hasPrefix(zonePrefix) else { return nil }
        let zoneCode = String(code.dropFirst(zonePrefix.count))
        guard let zone = CourtZone(code: zoneCode) else { return nil }
        self = .zone(zone)
    }
}

extension ShotOrigin: CaseIterable {
    /// Every possible origin, derived from `CourtZone.allCases` plus the
    /// 7 m mark so this list cannot drift as zones are added.
    public static var allCases: [ShotOrigin] {
        CourtZone.allCases.map(ShotOrigin.zone) + [.sevenMeters]
    }
}

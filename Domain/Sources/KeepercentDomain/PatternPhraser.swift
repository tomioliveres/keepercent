/// Turns a `ScoutingPattern` into one short English sentence. Deterministic
/// and offline: it is both what the patterns list shows and the facts the
/// on-device model may rephrase, so every number in it comes straight from
/// the pattern's tallies — never a rate it computed.
public enum PatternPhraser {
    public static func sentence(for pattern: ScoutingPattern) -> String {
        let count = "\(pattern.tally.successes) of \(pattern.tally.attempts)"
        switch pattern.kind {
        case .line(let line):
            return "Shoots \(name(line)) \(count)"
        case .lineFromSector(let line, let sector, let hand):
            let group = hand.map { "\(name($0)) from \(name(sector))" } ?? "From \(name(sector))"
            return "\(group): shoots \(name(line)) \(count)"
        case .height(let height):
            return "Aims \(name(height)) \(count)"
        case .side(let side):
            return "Aims \(name(side)) \(count)"
        case .deliveryHeight(let delivery, let height):
            return "\(name(delivery)), aims \(name(height)) \(count)\(goals(pattern.conversion))"
        case .deliverySide(let delivery, let side):
            return "\(name(delivery)), aims \(name(side)) \(count)\(goals(pattern.conversion))"
        case .approachSide(let approach, let side):
            return "\(name(approach)), aims \(name(side)) \(count)"
        case .sevenMeterHeight(let height):
            return "7 m: aims \(name(height)) \(count)"
        case .sevenMeterSide(let side):
            return "7 m: aims \(name(side)) \(count)"
        case .origin(let zone):
            return "Shoots from \(name(zone.sector)) (\(zone.depth.rawValue)) \(count)"
        case .distance:
            return "Scores from near \(count) vs far \(of(pattern.contrast))"
        case .repeatAfterGoal:
            return "After scoring, repeats the same zone \(count)"
        case .concededHeight(let height):
            return "Concedes \(name(height)) \(count) goals"
        case .concededSide(let side):
            return "Concedes \(name(side)) \(count) goals"
        case .deliverySaves:
            return "Saves standing shots \(count) vs jump shots \(of(pattern.contrast))"
        case .sevenMeterSaves:
            return "7 m: saves \(count)"
        }
    }

    private static func of(_ tally: Tally?) -> String {
        guard let tally else { return "" }
        return "\(tally.successes) of \(tally.attempts)"
    }

    /// " (3 goals)", or nothing when there is no conversion to add.
    private static func goals(_ conversion: Tally?) -> String {
        guard let conversion else { return "" }
        return " (\(conversion.successes) \(conversion.successes == 1 ? "goal" : "goals"))"
    }

    private static func name(_ line: ShotLine) -> String {
        switch line {
        case .crossShot: return "cross-court"
        case .nearPost: return "near post"
        case .neutral: return "down the middle"
        }
    }

    private static func name(_ hand: Handedness) -> String {
        switch hand {
        case .left: return "Left-handed"
        case .right: return "Right-handed"
        }
    }

    private static func name(_ sector: CourtSector) -> String {
        switch sector {
        case .leftWing: return "left wing"
        case .leftBack: return "left back"
        case .center: return "center"
        case .rightBack: return "right back"
        case .rightWing: return "right wing"
        }
    }

    private static func name(_ height: ShotHeight) -> String {
        switch height {
        case .top: return "high"
        case .middle: return "mid-height"
        case .bottom: return "low"
        }
    }

    private static func name(_ side: ShotSide) -> String {
        switch side {
        case .left: return "left"
        case .center: return "center"
        case .right: return "right"
        }
    }

    private static func name(_ delivery: ShotDelivery) -> String {
        switch delivery {
        case .jump: return "When jumping"
        case .standing: return "When standing"
        }
    }

    private static func name(_ approach: ShotApproach) -> String {
        switch approach {
        case .fromLeft: return "Coming from the left"
        case .fromRight: return "Coming from the right"
        case .straight: return "Coming straight"
        }
    }
}

import Foundation

/// Turns a `ScoutingPattern` into one short sentence in `locale`'s language
/// (English, or Spanish from Spain or Latin America). Deterministic and
/// offline: it is both what the patterns list shows and the facts the
/// on-device model may rephrase, so every number in it comes straight from
/// the pattern's tallies — never a rate it computed.
///
/// Each sentence is one catalog entry whose interpolated parts become format
/// arguments, so a translation may reorder them; the short names inserted
/// into it are looked up by stable keys (see Localization.swift).
public enum PatternPhraser {
    public static func sentence(for pattern: ScoutingPattern, locale: Locale = .current) -> String {
        let phrase = Phrase(locale: locale)
        let count = phrase.of(pattern.tally)
        switch pattern.kind {
        case .line(let line):
            return String(domain: "Shoots \(phrase.name(line)) \(count)", locale: locale)
        case .lineFromSector(let line, let sector, let hand?):
            return String(
                domain: "\(phrase.name(hand)) from \(phrase.name(sector)): shoots \(phrase.name(line)) \(count)",
                locale: locale
            )
        case .lineFromSector(let line, let sector, nil):
            return String(domain: "From \(phrase.name(sector)): shoots \(phrase.name(line)) \(count)", locale: locale)
        case .height(let height):
            return String(domain: "Aims \(phrase.name(height)) \(count)", locale: locale)
        case .side(let side):
            return String(domain: "Aims \(phrase.name(side)) \(count)", locale: locale)
        case .deliveryHeight(let delivery, let height):
            return String(
                domain: "\(phrase.name(delivery)), aims \(phrase.name(height)) \(count)\(phrase.goals(pattern.conversion))",
                locale: locale
            )
        case .deliverySide(let delivery, let side):
            return String(
                domain: "\(phrase.name(delivery)), aims \(phrase.name(side)) \(count)\(phrase.goals(pattern.conversion))",
                locale: locale
            )
        case .approachSide(let approach, let side):
            return String(domain: "\(phrase.name(approach)), aims \(phrase.name(side)) \(count)", locale: locale)
        case .sevenMeterHeight(let height):
            return String(domain: "7 m: aims \(phrase.name(height)) \(count)", locale: locale)
        case .sevenMeterSide(let side):
            return String(domain: "7 m: aims \(phrase.name(side)) \(count)", locale: locale)
        case .origin(let zone):
            return String(
                domain: "Shoots from \(phrase.name(zone.sector)) (\(phrase.name(zone.depth))) \(count)",
                locale: locale
            )
        case .distance:
            return String(domain: "Scores from near \(count) vs far \(phrase.of(pattern.contrast))", locale: locale)
        case .repeatAfterGoal:
            return String(domain: "After scoring, repeats the same zone \(count)", locale: locale)
        case .concededHeight(let height):
            return String(domain: "Concedes \(phrase.name(height)) \(count) goals", locale: locale)
        case .concededSide(let side):
            return String(domain: "Concedes \(phrase.name(side)) \(count) goals", locale: locale)
        case .deliverySaves:
            return String(
                domain: "Saves standing shots \(count) vs jump shots \(phrase.of(pattern.contrast))",
                locale: locale
            )
        case .sevenMeterSaves:
            return String(domain: "7 m: saves \(count)", locale: locale)
        }
    }
}

/// The short pieces `PatternPhraser` inserts into its sentences, in one
/// locale's language.
private struct Phrase {
    let locale: Locale

    /// "5 of 6", or nothing when there is no tally to show.
    func of(_ tally: Tally?) -> String {
        guard let tally else { return "" }
        return String(domain: "\(tally.successes) of \(tally.attempts)", locale: locale)
    }

    /// " (3 goals)", or nothing when there is no conversion to add.
    func goals(_ conversion: Tally?) -> String {
        guard let conversion else { return "" }
        return " (" + String(domain: "\(conversion.successes) goals", locale: locale) + ")"
    }

    func name(_ line: ShotLine) -> String {
        switch line {
        case .crossShot: String(domainKey: "line.crossShot", defaultValue: "cross-court", locale: locale)
        case .nearPost: String(domainKey: "line.nearPost", defaultValue: "near post", locale: locale)
        case .neutral: String(domainKey: "line.neutral", defaultValue: "down the middle", locale: locale)
        }
    }

    func name(_ hand: Handedness) -> String {
        switch hand {
        case .left: String(domainKey: "hand.left", defaultValue: "Left-handed", locale: locale)
        case .right: String(domainKey: "hand.right", defaultValue: "Right-handed", locale: locale)
        }
    }

    func name(_ sector: CourtSector) -> String {
        sector.displayName(locale: locale)
    }

    func name(_ depth: CourtDepth) -> String {
        depth.displayName(locale: locale)
    }

    func name(_ height: ShotHeight) -> String {
        switch height {
        case .top: String(domainKey: "height.top", defaultValue: "high", locale: locale)
        case .middle: String(domainKey: "height.middle", defaultValue: "mid-height", locale: locale)
        case .bottom: String(domainKey: "height.bottom", defaultValue: "low", locale: locale)
        }
    }

    func name(_ side: ShotSide) -> String {
        switch side {
        case .left: String(domainKey: "side.left", defaultValue: "left", locale: locale)
        case .center: String(domainKey: "side.center", defaultValue: "center", locale: locale)
        case .right: String(domainKey: "side.right", defaultValue: "right", locale: locale)
        }
    }

    func name(_ delivery: ShotDelivery) -> String {
        switch delivery {
        case .jump: String(domainKey: "delivery.jump", defaultValue: "When jumping", locale: locale)
        case .standing: String(domainKey: "delivery.standing", defaultValue: "When standing", locale: locale)
        }
    }

    func name(_ approach: ShotApproach) -> String {
        switch approach {
        case .fromLeft: String(domainKey: "approach.fromLeft", defaultValue: "Coming from the left", locale: locale)
        case .fromRight: String(domainKey: "approach.fromRight", defaultValue: "Coming from the right", locale: locale)
        case .straight: String(domainKey: "approach.straight", defaultValue: "Coming straight", locale: locale)
        }
    }
}

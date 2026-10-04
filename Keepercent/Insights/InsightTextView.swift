import Foundation
import SwiftUI
import KeepercentDomain

/// A presentational view: facts come from a filtered engine, never SwiftData.
struct InsightTextView: View {
    let facts: InsightFacts

    private var template: String {
        let appLocale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "en")
        return TemplateInsightWriter(locale: appLocale).write(facts)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Scouting insight").font(.headline)
            Text(template)
                .foregroundStyle(.secondary)
        }
    }
}

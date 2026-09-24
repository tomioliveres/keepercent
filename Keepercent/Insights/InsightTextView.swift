import SwiftUI
import KeepercentDomain

/// A presentational view: facts come from a filtered engine, never SwiftData.
struct InsightTextView: View {
    let facts: InsightFacts

    @State private var resolvedFacts: InsightFacts?
    @State private var resolvedText: String?

    private var template: String { TemplateInsightWriter().write(facts) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Scouting insight").font(.headline)
            Text(resolvedFacts == facts ? (resolvedText ?? template) : template)
                .foregroundStyle(.secondary)
        }
        .task(id: facts) {
            // A card never waits for the model to display a useful insight.
            resolvedFacts = nil
            resolvedText = nil
            let text = (try? await FoundationModelsInsightWriter().write(facts)) ?? template
            guard !Task.isCancelled else { return }
            resolvedText = text
            resolvedFacts = facts
        }
    }
}

import SwiftUI
import KeepercentDomain

struct MatchScopeOption: Identifiable {
    let id: UUID
    let label: String
}

/// No persistence access: options and selected scope belong to the container.
struct MatchScopePicker: View {
    let options: [MatchScopeOption]
    @Binding var scope: MatchScope

    private var selectedLabel: String {
        switch scope {
        case .all: String(localized: "All matches")
        case .match(let id): options.first { $0.id == id }?.label ?? String(localized: "Match unavailable")
        }
    }

    var body: some View {
        Menu {
            Picker("Match scope", selection: $scope) {
                Text("All matches").tag(MatchScope.all)
                ForEach(options) { option in
                    Text(option.label).tag(MatchScope.match(option.id))
                }
                if case .match(let id) = scope, !options.contains(where: { $0.id == id }) {
                    Text("Match unavailable").tag(scope)
                }
            }
        } label: {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Showing").font(.caption).foregroundStyle(.secondary)
                    Text(selectedLabel).multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.up.chevron.down").accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Match scope")
        .accessibilityValue(selectedLabel)
        .accessibilityIdentifier("match.scope")
    }
}

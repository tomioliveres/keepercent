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

    var body: some View {
        Picker("Match scope", selection: $scope) {
            Text("All matches").tag(MatchScope.all)
            ForEach(options) { option in
                Text(option.label).tag(MatchScope.match(option.id))
            }
            if case .match(let id) = scope, !options.contains(where: { $0.id == id }) {
                Text("Match unavailable").tag(scope)
            }
        }
    }
}

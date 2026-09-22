// NewTeamSheet collects a rival team's name for TeamsView's "new team"
// action. PRESENTATIONAL: it holds only a text binding and reports intent
// through a closure. It never checks the name for emptiness itself —
// `RivalTeam.init`'s blank-name rule is what actually validates it, in
// TeamsView (CLAUDE.md: a view must never re-implement a rule the domain
// already owns) — `errorMessage` is only ever a message TeamsView read
// back from a caught `RivalTeamError`.

import SwiftUI

struct NewTeamSheet: View {
    @Binding var name: String
    let errorMessage: String?
    let onCreate: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Team name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Rival Team")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: onCreate)
                }
            }
        }
    }
}

#Preview("NewTeamSheet") {
    NewTeamSheet(name: .constant(""), errorMessage: nil, onCreate: {})
}

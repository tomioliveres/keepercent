import SwiftUI
import SwiftData
import KeepercentDomain

/// Rivals container. A plain stack keeps team selection explicit on every device.
struct TeamsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredRivalTeam.name) private var teams: [StoredRivalTeam]
    @State private var isPresentingNewTeamSheet = false
    @State private var newTeamName = ""
    @State private var newTeamErrorMessage: String?

    var body: some View {
        NavigationStack {
            List(teams) { team in
                NavigationLink {
                    RosterEditorView(team: team)
                } label: { Text(team.name) }
            }
            .overlay {
                if teams.isEmpty {
                    ContentUnavailableView("No Rivals", systemImage: "person.3",
                        description: Text("Create a rival team to add players and start scouting."))
                }
            }
            .navigationTitle("Rivals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        newTeamName = ""
                        newTeamErrorMessage = nil
                        isPresentingNewTeamSheet = true
                    } label: { Label("New Team", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $isPresentingNewTeamSheet) {
                NewTeamSheet(name: $newTeamName, errorMessage: newTeamErrorMessage, onCreate: createTeam)
            }
        }
    }

    private func createTeam() {
        do {
            let team = try RivalTeam(name: newTeamName)
            modelContext.insert(StoredRivalTeam(name: team.name))
            try modelContext.save()
            isPresentingNewTeamSheet = false
            newTeamErrorMessage = nil
        } catch {
            modelContext.rollback()
            newTeamErrorMessage = rosterErrorMessage(error)
        }
    }
}

#Preview("TeamsView") {
    TeamsView()
        .modelContainer(for: KeepercentSchema.models, inMemory: true)
}

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
    @State private var renamingTeam: StoredRivalTeam?
    @State private var pendingDeletion: StoredRivalTeam?
    @State private var renamedName = ""
    @State private var renameError: String?
    @State private var deletionError: String?

    var body: some View {
        NavigationStack {
            List(teams) { team in
                HStack {
                    NavigationLink {
                        RosterEditorView(team: team)
                    } label: { Text(team.name) }
                    Menu { actions(for: team) } label: {
                        Image(systemName: "ellipsis.circle").frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("Actions for \(team.name)")
                }
                .contextMenu { actions(for: team) }
                .swipeActions(allowsFullSwipe: false) {
                    Button("Delete") { pendingDeletion = team }.tint(.red)
                    Button("Rename") { beginRenaming(team) }
                }
            }
            .overlay {
                if teams.isEmpty {
                    ContentUnavailableView {
                        Label("No Rivals", systemImage: "person.3")
                    } description: {
                        Text("Create a rival team to add players and start scouting.")
                    } actions: {
                        Button("New Team", action: beginCreatingTeam)
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Rivals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: beginCreatingTeam) { Label("New Team", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $isPresentingNewTeamSheet) {
                NewTeamSheet(name: $newTeamName, errorMessage: newTeamErrorMessage, onCreate: createTeam)
            }
            .sheet(item: $renamingTeam) { team in
                NewTeamSheet(name: $renamedName, errorMessage: renameError, onCreate: {
                    do {
                        try ScoutingDataActions.rename(team, to: renamedName, in: modelContext)
                        renamingTeam = nil
                    } catch { renameError = rosterErrorMessage(error) }
                }, isRenaming: true)
            }
            .alert("Delete this team?", isPresented: Binding(
                get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } }
            ), presenting: pendingDeletion) { team in
                Button("Delete Team", role: .destructive) {
                    do { try ScoutingDataActions.delete(team, in: modelContext) }
                    catch { deletionError = error.localizedDescription }
                    pendingDeletion = nil
                }
                Button("Cancel", role: .cancel) { pendingDeletion = nil }
            } message: { team in
                Text("This permanently deletes \(team.name) and its club roster. Matches, recorded shots and match participant snapshots are preserved, but will show Deleted Rival. This cannot be undone.")
            }
            .alert("Couldn't Complete Action", isPresented: Binding(
                get: { deletionError != nil }, set: { if !$0 { deletionError = nil } }
            )) {
                Button("OK", role: .cancel) { deletionError = nil }
            } message: { Text(deletionError ?? "") }
        }
    }

    @ViewBuilder private func actions(for team: StoredRivalTeam) -> some View {
        Button("Rename Team") { beginRenaming(team) }
        Button("Delete Team", role: .destructive) { pendingDeletion = team }
    }

    private func beginRenaming(_ team: StoredRivalTeam) {
        renamedName = team.name
        renameError = nil
        renamingTeam = team
    }

    private func beginCreatingTeam() {
        newTeamName = ""
        newTeamErrorMessage = nil
        isPresentingNewTeamSheet = true
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

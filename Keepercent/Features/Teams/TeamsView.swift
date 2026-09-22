// TeamsView is the app's entry screen (T3.1 item 7): a sidebar of rival
// teams plus the selected team's roster editor in the detail pane, using
// `NavigationSplitView` for adaptive iPad/iPhone layout per docs/mvp.md
// §6 item 1 and §7. It is the CONTAINER for the teams list — the only
// place in this feature that owns `@Query`/`ModelContext` for
// `StoredRivalTeam` itself; the selected team is handed straight to
// `RosterEditorView`, which is its own container for everything under it
// (CLAUDE.md's container/presentational rule).
//
// ## Demo seed wiring (T3.1 item 6)
//
// `DemoDataSeeder.seed(into:)` has existed since T1.5 but was called from
// nowhere, so the app opened on an empty screen. It needs a real
// `ModelContext`, which only exists inside the view hierarchy under
// `.modelContainer(...)` (set up in KeepercentApp) — there is no such
// context available any earlier, e.g. in `KeepercentApp` itself. This view
// is now the app's actual entry screen, so running the seed from its
// `.task` is "once per launch with a real ModelContext" exactly as asked:
// the very first screen the user sees triggers it, before anything else
// needs the data. `.task` re-runs on every appearance of this view, not
// just app launch, but `DemoDataSeeder.seed` is documented idempotent (one
// short-circuiting fetch when the demo team already exists), so a repeat
// call back into this screen is a cheap no-op, not a growing cost. A
// thrown seeding error is never swallowed: it is surfaced as an alert,
// per this task's explicit instruction.
//
// ## Keeping the T2.x scaffold reachable (T3.1 item 7)
//
// `ContentView` is kept, unmodified, as the hand-verification harness for
// `GoalView`/`CourtView` — it is not this task's to delete, and T3.3 will
// build the real shot-entry screen on top of it. It stays reachable
// through a secondary toolbar action here rather than a tab, since the
// teams screen — not the scaffold — is now the app's real front door.

import SwiftUI
import SwiftData
import KeepercentDomain

struct TeamsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredRivalTeam.name) private var teams: [StoredRivalTeam]

    @State private var selectedTeamID: PersistentIdentifier?
    @State private var isPresentingNewTeamSheet = false
    @State private var newTeamName = ""
    @State private var newTeamErrorMessage: String?
    @State private var isShowingScaffold = false
    @State private var seedErrorMessage: String?

    private var selectedTeam: StoredRivalTeam? {
        guard let selectedTeamID else { return nil }
        return teams.first { $0.persistentModelID == selectedTeamID }
    }

    var body: some View {
        NavigationSplitView {
            List(teams, selection: $selectedTeamID) { team in
                Text(team.name)
            }
            .navigationTitle("Rival Teams")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        newTeamName = ""
                        newTeamErrorMessage = nil
                        isPresentingNewTeamSheet = true
                    } label: {
                        Label("New Team", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button("Drawing Scaffold (T2.x)") {
                        isShowingScaffold = true
                    }
                }
            }
        } detail: {
            if let selectedTeam {
                // One identity per team: without it SwiftUI reuses the same
                // editor when the selection changes, and its navigation path
                // would still hold the previous team's open session.
                RosterEditorView(team: selectedTeam)
                    .id(selectedTeam.persistentModelID)
            } else {
                ContentUnavailableView(
                    "Select a Team",
                    systemImage: "person.3",
                    description: Text("Choose a rival team from the list, or create one.")
                )
            }
        }
        .sheet(isPresented: $isPresentingNewTeamSheet) {
            NewTeamSheet(name: $newTeamName, errorMessage: newTeamErrorMessage, onCreate: createTeam)
        }
        .sheet(isPresented: $isShowingScaffold) {
            NavigationStack {
                ContentView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { isShowingScaffold = false }
                        }
                    }
            }
        }
        .task {
            do {
                try DemoDataSeeder.seed(into: modelContext)
            } catch {
                seedErrorMessage = "Couldn't load demo data: \(error.localizedDescription)"
            }
            selectFirstTeamIfNeeded()
        }
        .onChange(of: teams) {
            selectFirstTeamIfNeeded()
        }
        .alert(
            "Demo Data",
            isPresented: Binding(
                get: { seedErrorMessage != nil },
                set: { isPresented in if !isPresented { seedErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { seedErrorMessage = nil }
        } message: {
            Text(seedErrorMessage ?? "")
        }
    }

    /// Selects the first team once teams exist and nothing is selected yet
    /// — including right after the demo seed inserts one, so the app opens
    /// on the demo rival team's roster instead of the empty "select a
    /// team" placeholder.
    private func selectFirstTeamIfNeeded() {
        guard selectedTeamID == nil, let first = teams.first else { return }
        selectedTeamID = first.persistentModelID
    }

    /// Creates a rival team from `newTeamName`. `RivalTeam.init` is what
    /// actually validates the name (throws `RivalTeamError.blankName`);
    /// this function never checks emptiness itself, only reports back
    /// whatever that initializer, or the SwiftData save, threw.
    private func createTeam() {
        do {
            let team = try RivalTeam(name: newTeamName)
            let stored = StoredRivalTeam(name: team.name)
            modelContext.insert(stored)
            try modelContext.save()
            selectedTeamID = stored.persistentModelID
            isPresentingNewTeamSheet = false
            newTeamErrorMessage = nil
        } catch {
            // Same reasoning as RosterEditorView's actions: a failed save
            // must not leave the new team in the list beside its error.
            modelContext.rollback()
            newTeamErrorMessage = rosterErrorMessage(error)
        }
    }
}

#Preview("TeamsView") {
    TeamsView()
        .modelContainer(for: KeepercentSchema.models, inMemory: true)
}

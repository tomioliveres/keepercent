import SwiftUI
import SwiftData

/// Root container owns launch seeding; changing tabs never selects a rival.
struct AppNavigationView: View {
    var seedDemoDataOnAppear = true
    @Environment(\.modelContext) private var modelContext
    @State private var seedErrorMessage: String?
    @State private var isShowingScaffold = false

    var body: some View {
        TabView {
            Tab("Matches", systemImage: "sportscourt") {
                NavigationStack {
                    MatchesView()
                        .toolbar { debugMenu }
                }
            }
            Tab("Rivals", systemImage: "person.3") {
                TeamsView()
            }
            Tab("My Club", systemImage: "shield") {
                NavigationStack {
                    MyClubView()
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Button("Own Team Roster") { isShowingOwnRoster = true }
                            }
                        }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .sheet(isPresented: $isShowingOwnRoster) { OwnTeamRosterView() }
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
            guard seedDemoDataOnAppear else { return }
            do {
                try DemoDataSeeder.seed(into: modelContext)
            } catch {
                seedErrorMessage = String(localized: "Couldn't load demo data: \(error.localizedDescription)")
            }
        }
        .alert("Demo Data", isPresented: Binding(
            get: { seedErrorMessage != nil },
            set: { if !$0 { seedErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { seedErrorMessage = nil }
        } message: { Text(seedErrorMessage ?? "") }
    }

    @State private var isShowingOwnRoster = false

    @ToolbarContentBuilder
    private var debugMenu: some ToolbarContent {
        #if DEBUG
        ToolbarItem(placement: .secondaryAction) {
            Menu {
                Button("Drawing Scaffold (T2.x)") { isShowingScaffold = true }
            } label: { Label("More", systemImage: "ellipsis") }
        }
        #endif
    }
}

import SwiftUI
import SwiftData

/// All persisted sessions remain visible, including history whose rival was removed.
struct MatchesView: View {
    @Query(sort: \StoredSession.date, order: .reverse) private var sessions: [StoredSession]
    @State private var isCreatingMatch = false
    @State private var pendingSession: StoredSession?
    @State private var selectedSession: StoredSession?

    var body: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView {
                    Label("No Matches", systemImage: "sportscourt")
                } description: {
                    Text("Start a match to record shots against a rival.")
                } actions: {
                    Button("New Match") { isCreatingMatch = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List(sessions) { session in
                    ManagedMatchRow(session: session) { selectedSession = session }
                }
            }
        }
        .navigationTitle("Matches")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isCreatingMatch = true } label: {
                    Label("New Match", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isCreatingMatch, onDismiss: {
            // Present entry only after the creation sheet has finished dismissing.
            selectedSession = pendingSession
            pendingSession = nil
        }) {
            MatchCreationSheet { pendingSession = $0 }
        }
        .fullScreenCover(item: $selectedSession) { session in
            SessionEntryCover(session: session)
        }
    }

}

/// Modal navigation chrome stays outside entry, preserving its layout and writes.
struct SessionEntryCover: View {
    let session: StoredSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let team = session.rivalTeam {
                    SessionView(team: team, session: session)
                } else {
                    ContentUnavailableView("Deleted Rival", systemImage: "person.3",
                        description: Text("Shot entry is unavailable because this rival was deleted."))
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

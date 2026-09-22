// SessionView is a placeholder for one scouting session, shown after
// tapping a session on its team's screen, and automatically after
// starting a new one (T3.2 item 5). T3.3 replaces this body with the real
// shot-entry screen; until then it only confirms which session was
// opened, so tapping into a session never dead-ends on a blank screen.
// PRESENTATIONAL per CLAUDE.md: it draws the plain values it is given,
// never a `StoredSession`.

import SwiftUI
import KeepercentDomain

struct SessionView: View {
    let teamName: String
    let kind: SessionKind?
    let matchDate: Date
    let shotCount: Int

    var body: some View {
        ContentUnavailableView {
            Label(teamName, systemImage: "sportscourt")
        } description: {
            VStack(spacing: 8) {
                Text("\(kind.map(sessionKindLabel) ?? "Unknown kind") session · \(matchDate.formatted(date: .abbreviated, time: .omitted))")
                Text("\(shotCount) shot\(shotCount == 1 ? "" : "s") recorded so far.")
                Text("Shot entry isn't available yet.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(teamName)
    }
}

#Preview("SessionView") {
    NavigationStack {
        SessionView(teamName: "CB Handbol Test", kind: .live, matchDate: .now, shotCount: 8)
    }
}

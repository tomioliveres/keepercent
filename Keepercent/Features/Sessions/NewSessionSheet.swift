// NewSessionSheet collects a session's kind and match date, for
// MatchCreationSheet's "New Match" action (docs/mvp.md §6 item 2: "rival
// and kind (live/video)"). PRESENTATIONAL per CLAUDE.md: it receives only
// bindings and a closure, and reports intent through `onStart`. It never
// touches SwiftData or builds a `KeepercentDomain.Session` itself — the
// container builds `Session(kind:matchDate:today:calendar:)` and reports
// back whatever `SessionError` it threw (see SessionMessaging.swift),
// the same division of labour NewTeamSheet/RivalTeamError use.
//
// The rival has already been selected by the container, either from Matches
// or the team's own screen. Display its name to confirm the chosen opponent.
//
// The match date range is `...Date.now`: the DatePicker itself can never
// reach a future date, so `Session.init`'s "no future match date" rule is
// unreachable through this UI, not just rejected after the fact — it
// starts on today, per the T3.2 decision. `SessionError.matchDateInFuture`
// is still handled end to end (see MatchCreationSheet), the
// same defence-in-depth `AddUnknownPlayerView` uses for its own range.

import SwiftUI
import KeepercentDomain

struct NewSessionSheet: View {
    @Binding var kind: SessionKind
    @Binding var matchDate: Date
    let onStart: () -> Void
    var available: [Player] = []
    @Binding var participants: [Player]
    var ownTeamName: String? = nil
    var ownAvailable: [Player] = []
    @Binding var includeOwn: Bool
    @Binding var ownParticipants: [Player]
    var rivalName: String? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                if let rivalName {
                    Section("Rival") { Text(rivalName) }
                }
                MatchRosterSelection(available: available, players: $participants)
                OwnMatchRosterSelection(teamName: ownTeamName, available: ownAvailable,
                                        included: $includeOwn, players: $ownParticipants)
                Section {
                    Picker("Kind", selection: $kind) {
                        ForEach(SessionKind.allCases, id: \.self) { kind in
                            Text(sessionKindLabel(kind)).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    DatePicker(
                        "Match Date",
                        selection: $matchDate,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                } footer: {
                    Text("The date the match was actually played, not today's date — for a video session that can be earlier.")
                }
            }
            .navigationTitle("New Match")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start", action: onStart)
                }
            }
        }
    }
}

#Preview("NewSessionSheet") {
    NewSessionSheet(kind: .constant(.live), matchDate: .constant(.now), onStart: {}, participants: .constant([]),
                    includeOwn: .constant(false), ownParticipants: .constant([]))
}

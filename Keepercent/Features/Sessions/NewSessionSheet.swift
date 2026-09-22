// NewSessionSheet collects a session's kind and match date, for
// RosterEditorView's "New Session" action (docs/mvp.md §6 item 2: "rival
// and kind (live/video)"). PRESENTATIONAL per CLAUDE.md: it receives only
// bindings and a closure, and reports intent through `onStart`. It never
// touches SwiftData or builds a `KeepercentDomain.Session` itself — the
// container builds `Session(kind:matchDate:today:calendar:)` and reports
// back whatever `SessionError` it threw (see SessionMessaging.swift),
// the same division of labour NewTeamSheet/RivalTeamError use.
//
// The rival team itself is not a field here: a session is always started
// from that team's own screen, so the relationship is implicit (see
// Session.swift's header and T3.2 in odd/tasks/keepercent.md).
//
// The match date range is `...Date.now`: the DatePicker itself can never
// reach a future date, so `Session.init`'s "no future match date" rule is
// unreachable through this UI, not just rejected after the fact — it
// starts on today, per the T3.2 decision. `SessionError.matchDateInFuture`
// is still handled end to end (see RosterEditorView.startSession), the
// same defence-in-depth `AddUnknownPlayerView` uses for its own range.

import SwiftUI
import KeepercentDomain

struct NewSessionSheet: View {
    @Binding var kind: SessionKind
    @Binding var matchDate: Date
    let onStart: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
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
            .navigationTitle("New Session")
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
    NewSessionSheet(kind: .constant(.live), matchDate: .constant(.now), onStart: {})
}

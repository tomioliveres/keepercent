// ShotLogView lists a session's shots newest first and lets the scout
// delete any one of them after a confirmation (T3.4 decision: delete only,
// no editing — a mistake noticed several plays later is fixed just as well
// by deleting that shot and recording it again).
//
// CONTAINER per CLAUDE.md, the same shape as `RosterEditorView` and
// `SessionView`: it owns `@Environment(\.modelContext)` and performs the
// one-row delete + save itself, rolling back on failure exactly like
// `SessionView.undoLastShot` and `RosterEditorView.remove`. Keeping the
// write here (rather than reporting a tap back to `SessionView`) means the
// same "touches one row, rolls back in the catch" shape covers every write
// path in this feature, including this one.
//
// ## Undo invariant (T3.4)
//
// `SessionView`'s last-shot card tracks the shot it echoes by
// `PersistentIdentifier` (`SessionView.lastShotID`), never by index or a
// "most recently inserted" query — that was already true before this file
// existed. `onDeletedShot` reports the deleted row's identity back to
// `SessionView` so it can compare that id against `lastShotID` and drop the
// card's Undo the instant the shot it would undo no longer exists, without
// ever touching a different, still-live shot. See `SessionView.swift`'s own
// header for the two independent guards that already protect a
// same-session undo; this is the guard for a delete coming from the log.

import SwiftUI
import SwiftData
import KeepercentDomain

struct ShotLogView: View {
    let session: StoredSession
    let onDeletedShot: (PersistentIdentifier) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var pendingDelete: StoredShot?
    @State private var errorMessage: String?

    /// Newest first, per T3.4's decision. A plain sort on `session.shots`,
    /// the same inline shape `RosterEditorView.sortedSessions` already uses
    /// for its own SwiftData relationship — there is no scouting rule here,
    /// just "most recent on top", so it stays out of `Domain/`.
    private var shotsNewestFirst: [StoredShot] {
        session.shots.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            Group {
                if shotsNewestFirst.isEmpty {
                    ContentUnavailableView(
                        "No Shots Recorded",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Shots recorded for this session will appear here.")
                    )
                } else {
                    List {
                        ForEach(shotsNewestFirst, id: \.persistentModelID) { stored in
                            Text(summaryText(for: stored))
                                .font(.subheadline.monospaced())
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        pendingDelete = stored
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("Shot Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            // Confirmation before every delete (T3.4's explicit
            // requirement): the swipe action only stages `pendingDelete`,
            // nothing is removed until this dialog's own destructive button
            // is tapped.
            .confirmationDialog(
                "Delete this shot?",
                isPresented: Binding(
                    get: { pendingDelete != nil },
                    set: { isPresented in if !isPresented { pendingDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let pendingDelete {
                        delete(pendingDelete)
                    }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("This can't be undone. Recording it again is the only way back.")
            }
            .alert(
                "Couldn't Delete Shot",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { isPresented in if !isPresented { errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    /// `ShotSummary`'s own text when the row decodes; a placeholder, never
    /// a crash, matching the "a corrupt row survives as a row" contract
    /// `StoredSession.kind` and `StoredShot.domainShot` already use
    /// elsewhere (see `SessionRowView`'s "Unknown kind").
    private func summaryText(for stored: StoredShot) -> String {
        guard let shot = stored.domainShot else { return "Unrecorded shot" }
        return ShotSummary(shot: shot).text
    }

    /// Touches exactly one row: removes it from the relationship first —
    /// the lesson from `SessionView.undoLastShot`, whose header explains
    /// why leaving a deleted row in `session.shots` keeps a stale count on
    /// screen — then deletes and saves, rolling back on failure like every
    /// other write path in this app.
    private func delete(_ stored: StoredShot) {
        let id = stored.persistentModelID
        session.shots.removeAll { $0.persistentModelID == id }
        modelContext.delete(stored)
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = "Couldn't delete this shot (\(error.localizedDescription))."
            return
        }
        onDeletedShot(id)
    }
}

#Preview("ShotLogView") {
    let schema = Schema(KeepercentSchema.models)
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let team = StoredRivalTeam(name: "CB Handbol Test")
    let session = StoredSession(date: .now, kindCode: SessionKind.live.rawValue, rivalTeam: team)
    let shot = Shot(
        attackingSide: .rival,
        shooter: Player(number: 7),
        target: .post(.crossbarCenter),
        outcome: .post,
        date: .now
    )
    let stored = StoredShot(shot, shooter: nil, facingGoalkeeper: nil)
    session.shots = [stored]
    team.sessions = [session]
    container.mainContext.insert(team)

    return ShotLogView(session: session, onDeletedShot: { _ in })
        .modelContainer(container)
}

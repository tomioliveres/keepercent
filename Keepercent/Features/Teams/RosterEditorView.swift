// RosterEditorView is the CONTAINER for one rival team's roster
// (docs/mvp.md §6 item 1, T3.1). It owns `ModelContext` and every
// `StoredPlayer`/`StoredRivalTeam` access for this feature; its
// presentational children (`RosterGridView`, `PlayerTileView`,
// `PlayerEditorView`, `AddUnknownPlayerView`) only ever see
// `KeepercentDomain.Player` values and plain `Int`s, never a stored row.
//
// ## Write-back: how a new `Roster` becomes SwiftData mutations
//
// `Roster` is a value type: every mutating operation (`add`, `update`,
// `remove`) returns a WHOLE NEW `Roster`, but SwiftData wants existing
// `StoredPlayer` rows mutated in place — replacing the array wholesale
// (deleting every row and re-inserting the new roster's players) would
// churn every `StoredShot.shooter`/`.facingGoalkeeper` relationship on
// every edit, silently orphaning recorded shots. That is exactly the
// defect this task exists to prevent (see item 5's "load-bearing
// behaviour").
//
// This container never does that. Every UI action already knows exactly
// ONE `StoredPlayer` row it concerns — the one the "+" tile is about to
// create, or the one row an edit/delete sheet was opened for — so instead
// of diffing an old roster against a new one, this file:
//
//   1. Rebuilds a fresh `Roster` from `team.players` (via `currentRoster()`
//      below) and asks it to perform the SAME operation the UI action
//      implies (`addUnknown`, `update`, `remove`). This is what actually
//      validates the change — uniqueness, range, and (for removal) the
//      recorded-shot-count rule — against the CURRENT full roster, using
//      only the domain's own rules. If it throws, NOTHING is written to
//      SwiftData, and the thrown error's own payload becomes the message
//      shown to the user (`rosterErrorMessage`).
//   2. Once that validation succeeds, applies exactly the one row-level
//      change the action implies, directly: `addUnknown` inserts one new
//      `StoredPlayer`; `update` mutates the four fields of the one
//      `StoredPlayer` instance the edit sheet was opened for, in place;
//      `remove` deletes that one row. No other row is ever touched, so no
//      other player's `StoredShot` relationships are ever disturbed.
//
// The validated `Roster` returned by step 1 is deliberately discarded
// after use — it exists to make the domain's rules run, not to be
// "applied" wholesale.
//
// ## Sessions (T3.2)
//
// This same screen also lists the team's sessions and starts new ones,
// following the same validate-then-write-one-row shape as the roster
// actions above: `startSession` builds `KeepercentDomain.Session` FIRST
// (which owns the "no future match date" rule), and only inserts a
// `StoredSession` if that succeeds. A session is started FROM a team's
// screen (Session.swift's header), so the rival team is never a field the
// user picks — `startSession` always attaches the new session to `team`.
//
// `path` is a `NavigationPath` local to this view, wrapped in its own
// `NavigationStack`, so tapping a session (or finishing "Start") can push
// straight to `SessionView` inside `TeamsView`'s existing
// `NavigationSplitView` detail column without that view needing to know
// about session navigation at all.

import SwiftUI
import SwiftData
import KeepercentDomain

struct RosterEditorView: View {
    let team: StoredRivalTeam
    /// See `TeamsView`'s own comment on this same `@State`: this view drives
    /// it, `TeamsView` only stores it. `path` (below) already tells this
    /// view exactly when a session is open — it is the one place besides
    /// `TeamsView` that decides where the user is — so reusing it as the
    /// signal, via `.onChange(of:)`, needs no second source of truth.
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Environment(\.modelContext) private var modelContext

    @State private var editingPlayer: StoredPlayer?
    @State private var isAddingUnknown = false
    @State private var addUnknownErrorMessage: String?
    @State private var actionError: RosterActionError?
    @State private var isPresentingNewSessionSheet = false
    @State private var newSessionKind: SessionKind = .live
    @State private var newSessionMatchDate: Date = .now
    @State private var newSessionErrorMessage: String?
    @State private var path = NavigationPath()

    /// A fresh `Roster` built from this team's current `StoredPlayer` rows,
    /// or the error that building it hit. Building can fail if the stored
    /// rows are somehow corrupt (e.g. a duplicate number slipped in outside
    /// this editor) — a case that should never happen given every write
    /// here goes through the same domain validation, but `try?` would
    /// silently swallow that corruption instead of surfacing it, so this is
    /// a `Result` the view explicitly branches on instead.
    private var rosterResult: Result<Roster, Error> {
        Result { try Roster(players: team.players.map(\.domainPlayer)) }
    }

    private func currentRoster() throws -> Roster {
        try Roster(players: team.players.map(\.domainPlayer))
    }

    /// This team's sessions, newest match date first (T3.2 item 4).
    private var sortedSessions: [StoredSession] {
        team.sessions.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                switch rosterResult {
                case .success(let roster):
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            RosterGridView(
                                players: roster.players,
                                onSelectPlayer: { player in
                                    // T4.3: opens the shooter card, the more
                                    // frequent reason to tap a roster row.
                                    // Editing moved to the context menu
                                    // below (`onEditPlayer`).
                                    path.append(ShooterCardRoute(playerNumber: player.number))
                                },
                                onEditPlayer: { player in
                                    editingPlayer = team.players.first { $0.number == player.number }
                                },
                                onTapAddUnknown: {
                                    addUnknownErrorMessage = nil
                                    isAddingUnknown = true
                                },
                                isScrollable: false
                            )

                            sessionsSection
                        }
                        .padding(.bottom)
                    }
                case .failure(let error):
                    ContentUnavailableView {
                        Label("Roster Data Problem", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text("This team's roster couldn't be loaded (\(error.localizedDescription)). Recorded shots are unaffected.")
                    }
                }
            }
            .navigationTitle(team.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        path.append(ScoutingRoute())
                    } label: {
                        Label("Scouting", systemImage: "chart.bar.xaxis")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        newSessionKind = .live
                        newSessionMatchDate = .now
                        newSessionErrorMessage = nil
                        isPresentingNewSessionSheet = true
                    } label: {
                        Label("New Session", systemImage: "plus.circle")
                    }
                }
            }
            .navigationDestination(for: PersistentIdentifier.self) { sessionID in
                if let session = team.sessions.first(where: { $0.persistentModelID == sessionID }) {
                    SessionView(team: team, session: session)
                } else {
                    ContentUnavailableView(
                        "Session Not Found",
                        systemImage: "exclamationmark.triangle",
                        description: Text("This session may have been removed.")
                    )
                }
            }
            // A distinct route type from `PersistentIdentifier` (sessions,
            // above): `NavigationStack` dispatches by the pushed value's
            // type, so this can be its own destination on the SAME `path`
            // without touching session navigation at all.
            .navigationDestination(for: ScoutingRoute.self) { _ in
                TeamScoutingView(team: team)
            }
            // T4.3: a distinct route type again, same reasoning as
            // `ScoutingRoute` above, but this one carries the tapped
            // shirt number so the destination knows which shooter to
            // narrow to.
            .navigationDestination(for: ShooterCardRoute.self) { route in
                ShooterCardView(team: team, playerNumber: route.playerNumber)
            }
        }
        // T3.3, decision ③: the team sidebar is hidden while a session is
        // open, so the entry screen's three-column layout gets the whole
        // iPad width. `path` is non-empty exactly when a session is pushed
        // (the only thing ever appended to it), so it is already the
        // signal this view needs — no separate "is a session open" flag.
        .onChange(of: path) {
            columnVisibility = path.isEmpty ? .automatic : .detailOnly
        }
        .sheet(item: $editingPlayer) { stored in
            let originalNumber = stored.number
            PlayerEditorView(
                player: stored.domainPlayer,
                shotCount: stored.shotsTaken.count,
                onSave: { updated in performUpdate(stored: stored, originalNumber: originalNumber, to: updated) },
                onDelete: { remove(stored) }
            )
            // The alert belongs to the SHEET, not to this view. Declared on
            // the parent, SwiftUI dismisses the open sheet in order to
            // present it, so a refused removal threw away any name,
            // goalkeeper or handedness edit the scout had made in the same
            // sheet but not yet saved. A refusal must cost nothing: the
            // rule says this player cannot be removed, not that the rest
            // of the work is forfeit. Presented here, the sheet stays open
            // with those edits intact and the explanation on top of them.
            .alert(
                "Couldn't Complete Action",
                isPresented: Binding(
                    get: { actionError != nil },
                    set: { isPresented in if !isPresented { actionError = nil } }
                ),
                presenting: actionError
            ) { _ in
                Button("OK", role: .cancel) { actionError = nil }
            } message: { error in
                Text(error.message)
            }
        }
        .sheet(isPresented: $isAddingUnknown) {
            AddUnknownPlayerView(
                allowedRange: Roster.numberRange,
                errorMessage: addUnknownErrorMessage,
                onAdd: { number in addUnknown(number: number) }
            )
        }
        // Same reasoning as the `editingPlayer` sheet above: the alert is
        // chained onto the presented `NewSessionSheet`, not onto this
        // view, so a rejected start leaves the sheet's own kind/date
        // picks on screen instead of SwiftUI dismissing the sheet to show
        // the alert.
        .sheet(isPresented: $isPresentingNewSessionSheet) {
            NewSessionSheet(kind: $newSessionKind, matchDate: $newSessionMatchDate, onStart: startSession)
                .alert(
                    "Couldn't Start Session",
                    isPresented: Binding(
                        get: { newSessionErrorMessage != nil },
                        set: { isPresented in if !isPresented { newSessionErrorMessage = nil } }
                    )
                ) {
                    Button("OK", role: .cancel) { newSessionErrorMessage = nil }
                } message: {
                    Text(newSessionErrorMessage ?? "")
                }
        }
    }

    /// The session list drawn below the roster grid (T3.2 item 4):
    /// newest match date first, each row a plain `SessionRowView` pushed
    /// via `path` rather than a `NavigationLink`, so the same push target
    /// is reachable from `startSession` too.
    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sessions")
                .font(.headline)
                .padding(.horizontal)

            if sortedSessions.isEmpty {
                Text("No sessions yet. Start one above.")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(sortedSessions, id: \.persistentModelID) { session in
                        Button {
                            path.append(session.persistentModelID)
                        } label: {
                            SessionRowView(
                                kind: session.kind,
                                matchDate: session.date,
                                shotCount: session.shots.count
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)

                        if session.persistentModelID != sortedSessions.last?.persistentModelID {
                            Divider().padding(.horizontal)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    /// The "+" tile: validates through `Roster.addUnknown`, then inserts
    /// exactly one new `StoredPlayer` built from `Player(number:)`'s own
    /// defaults (unnamed, not a goalkeeper, unknown handedness) — the same
    /// defaults the domain operation itself uses, so the stored row and
    /// the value that was validated can never disagree.
    private func addUnknown(number: Int) {
        do {
            let roster = try currentRoster()
            _ = try roster.addUnknown(number: number)
            let newPlayer = StoredPlayer(Player(number: number))
            team.players.append(newPlayer)
            modelContext.insert(newPlayer)
            try modelContext.save()
            isAddingUnknown = false
            addUnknownErrorMessage = nil
        } catch {
            // Undo whatever this action already applied to the context: a
            // failed save must not leave a row on screen next to the error
            // that says it was not stored. Every action saves immediately,
            // so there are never other pending changes for this to discard.
            modelContext.rollback()
            addUnknownErrorMessage = rosterErrorMessage(error)
        }
    }

    /// Validates the edit through `Roster.update`, then mutates the ONE
    /// `StoredPlayer` row the editor sheet was opened for, in place. See
    /// this file's header for why this never replaces or re-inserts the
    /// row.
    private func performUpdate(stored: StoredPlayer, originalNumber: Int, to updated: Player) {
        do {
            let roster = try currentRoster()
            _ = try roster.update(number: originalNumber, to: updated)
            stored.number = updated.number
            stored.name = updated.name
            stored.isGoalkeeper = updated.isGoalkeeper
            stored.handednessCode = updated.handedness?.rawValue
            try modelContext.save()
            editingPlayer = nil
        } catch {
            modelContext.rollback()
            actionError = RosterActionError(error)
        }
    }

    /// Validates removal through `Roster.remove`, passing the REAL count
    /// from the SwiftData relationship (`stored.shotsTaken.count`) — never
    /// a guess, never a hardcoded 0. `Array.count` is never negative, so
    /// `Roster.remove`'s precondition against a negative count can never
    /// trip here.
    private func remove(_ stored: StoredPlayer) {
        do {
            let roster = try currentRoster()
            let shotCount = stored.shotsTaken.count
            _ = try roster.remove(number: stored.number, recordedShotCount: shotCount)
            team.players.removeAll { $0.persistentModelID == stored.persistentModelID }
            modelContext.delete(stored)
            try modelContext.save()
            editingPlayer = nil
        } catch {
            modelContext.rollback()
            actionError = RosterActionError(error)
        }
    }

    /// "Start": builds `Session(kind:matchDate:today:calendar:)` FIRST —
    /// the only place the "no future match date" rule is enforced — and
    /// only inserts a `StoredSession` if that succeeds. `.current` and
    /// `.now` are read here, at the SwiftUI edge, exactly once; the
    /// domain itself never reads ambient system state (Session.swift).
    /// On success the new session is pushed onto `path` immediately, so
    /// starting a session opens it the same way tapping an existing one
    /// does.
    private func startSession() {
        do {
            let session = try Session(
                kind: newSessionKind,
                matchDate: newSessionMatchDate,
                today: .now,
                calendar: .current
            )
            let stored = StoredSession(date: session.matchDate, kindCode: session.kind.rawValue, rivalTeam: team)
            team.sessions.append(stored)
            modelContext.insert(stored)
            try modelContext.save()
            isPresentingNewSessionSheet = false
            newSessionErrorMessage = nil
            path.append(stored.persistentModelID)
        } catch {
            modelContext.rollback()
            newSessionErrorMessage = sessionErrorMessage(error)
        }
    }
}

/// A marker pushed onto `path` (T4.2) to reach `TeamScoutingView`: this
/// screen already needs nothing more than `team`, which the destination
/// closure captures directly, so the route carries no payload of its own —
/// it exists only to give `.navigationDestination(for:)` a distinct type
/// from the session push above.
private struct ScoutingRoute: Hashable {}

/// A route pushed onto `path` (T4.3) to reach `ShooterCardView` for one
/// rival shooter, identified by shirt number — the same identity
/// `StatsEngine.shots(by:)` already matches on.
private struct ShooterCardRoute: Hashable {
    let playerNumber: Int
}

/// A UI-ready wrapper so `.alert(presenting:)` can show whatever
/// `RosterEditorView`'s actions threw, worded by `rosterErrorMessage` —
/// see RosterErrorMessaging.swift.
private struct RosterActionError: Identifiable {
    let id = UUID()
    let message: String

    init(_ error: Error) {
        message = rosterErrorMessage(error)
    }
}

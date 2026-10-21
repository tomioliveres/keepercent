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
//      implies (`addUnknown`, `update`). This is what actually
//      validates the change — uniqueness and range — against the active roster, using
//      only the domain's own rules. If it throws, NOTHING is written to
//      SwiftData, and the thrown error's own payload becomes the message
//      shown to the user (`rosterErrorMessage`).
//   2. Once that validation succeeds, applies exactly the one row-level
//      change the action implies, directly: `addUnknown` inserts one new
//      `StoredPlayer`; `update` mutates the four fields of the one
//      `StoredPlayer` instance the edit sheet was opened for, in place;
//      archive marks that row inactive, never deletes it. No other row is touched, so no
//      other player's `StoredShot` relationships are ever disturbed.
//
// The validated `Roster` returned by step 1 is deliberately discarded
// after use — it exists to make the domain's rules run, not to be
// "applied" wholesale.
//
// ## Sessions (T3.2)
//
// Session creation is shared with Matches through MatchCreationSheet.
// Cards use the enclosing Rivals stack; shot entry covers the whole window.

import SwiftUI
import SwiftData
import KeepercentDomain

struct RosterEditorView: View {
    let team: StoredRivalTeam
    @Environment(\.modelContext) private var modelContext

    @State private var editingPlayer: StoredPlayer?
    @State private var isAddingUnknown = false
    @State private var addUnknownErrorMessage: String?
    @State private var actionError: RosterActionError?
    @State private var isPresentingNewSessionSheet = false
    @State private var selectedSession: StoredSession?
    @State private var pendingSession: StoredSession?
    @State private var isShowingScouting = false
    @State private var shooterRoute: ShooterCardRoute?
    @State private var goalkeeperRoute: GoalkeeperCardRoute?

    /// A fresh `Roster` built from this team's current `StoredPlayer` rows,
    /// or the error that building it hit. Building can fail if the stored
    /// rows are somehow corrupt (e.g. a duplicate number slipped in outside
    /// this editor) — a case that should never happen given every write
    /// here goes through the same domain validation, but `try?` would
    /// silently swallow that corruption instead of surfacing it, so this is
    /// a `Result` the view explicitly branches on instead.
    private var rosterResult: Result<Roster, Error> {
        Result { try Roster(players: team.players.filter { $0.archivedAt == nil }.map(\.domainPlayer)) }
    }

    private func currentRoster() throws -> Roster {
        try Roster(players: team.players.filter { $0.archivedAt == nil }.map(\.domainPlayer))
    }

    /// This team's sessions, newest match date first (T3.2 item 4).
    private var sortedSessions: [StoredSession] {
        team.sessions.sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            Group {
                switch rosterResult {
                case .success(let roster):
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            RosterGridView(
                                players: roster.players,
                                onSelectPlayer: { player in
                                    // T4.3/T4.4: opens the shooter card for
                                    // a field player, the goalkeeper card
                                    // for a goalkeeper — the more frequent
                                    // reason to tap a roster row. Editing
                                    // moved to the context menu below
                                    // (`onEditPlayer`).
                                    guard let id = player.id else { return }
                                    if player.isGoalkeeper {
                                        goalkeeperRoute = GoalkeeperCardRoute(playerID: id)
                                    } else {
                                        shooterRoute = ShooterCardRoute(playerID: id)
                                    }
                                },
                                onEditPlayer: { player in
                                    editingPlayer = team.players.first { $0.personID == player.id }
                                },
                                onTapAddUnknown: {
                                    addUnknownErrorMessage = nil
                                    isAddingUnknown = true
                                },
                                isScrollable: false
                            )

                            archivedPlayersSection
                            facingHistorySection
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
                        isShowingScouting = true
                    } label: {
                        Label("Scouting", systemImage: "chart.bar.xaxis")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingNewSessionSheet = true
                    } label: {
                        Label("New Match", systemImage: "plus.circle")
                    }
                }
            }
            .navigationDestination(isPresented: $isShowingScouting) {
                TeamScoutingView(team: team)
            }
            .navigationDestination(item: $shooterRoute) { route in
                ShooterCardView(team: team, playerID: route.playerID)
            }
            .navigationDestination(item: $goalkeeperRoute) { route in
                GoalkeeperCardView(team: team, playerID: route.playerID)
            }
        }
        .sheet(item: $editingPlayer) { stored in
            let originalNumber = stored.number
            PlayerEditorView(
                player: stored.domainPlayer,
                shotCount: stored.shotsTaken.count + stored.shotsFaced.count,
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
        .sheet(isPresented: $isPresentingNewSessionSheet, onDismiss: {
            selectedSession = pendingSession
            pendingSession = nil
        }) {
            MatchCreationSheet(rival: team) { pendingSession = $0 }
        }
        .fullScreenCover(item: $selectedSession) { session in
            SessionEntryCover(session: session)
        }
    }

    /// Team-local sessions open the same full-screen entry as global Matches.
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
                            selectedSession = session
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

    private var archivedPlayersSection: some View {
        VStack(alignment: .leading) {
            let archived = team.players.filter { $0.archivedAt != nil }.sorted(by: historyOrder)
            if !archived.isEmpty {
                Text("Archived players").font(.headline)
                ForEach(archived, id: \.persistentModelID) { player in
                    if let id = player.personID {
                        historyRow(player: player, destination: "Shooter") {
                            shooterRoute = ShooterCardRoute(playerID: id)
                        }
                        if player.isGoalkeeper || !player.shotsFaced.isEmpty {
                            historyRow(player: player, destination: "Goalkeeper") {
                                goalkeeperRoute = GoalkeeperCardRoute(playerID: id)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var facingHistorySection: some View {
        VStack(alignment: .leading) {
            let historical = team.players.filter {
                $0.archivedAt == nil && (!$0.shotsTaken.isEmpty || !$0.shotsFaced.isEmpty)
            }.sorted(by: historyOrder)
            if !historical.isEmpty {
                Text("Player history").font(.headline)
                ForEach(historical, id: \.persistentModelID) { player in
                    if let id = player.personID {
                        if !player.shotsTaken.isEmpty {
                            historyRow(player: player, destination: "Shooter") {
                                shooterRoute = ShooterCardRoute(playerID: id)
                            }
                        }
                        if !player.shotsFaced.isEmpty {
                            historyRow(player: player, destination: "Goalkeeper") {
                                goalkeeperRoute = GoalkeeperCardRoute(playerID: id)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Actions

    /// Relationships have no display order. Both lists share a total ordering,
    /// including archived identities that reused the same shirt number.
    private func historyOrder(_ first: StoredPlayer, _ second: StoredPlayer) -> Bool {
        if first.number != second.number { return first.number < second.number }
        func normalizedName(_ player: StoredPlayer) -> String {
            (player.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        }
        let firstName = normalizedName(first)
        let secondName = normalizedName(second)
        if firstName != secondName { return firstName < secondName }
        return (first.personID?.uuidString ?? "") < (second.personID?.uuidString ?? "")
    }

    /// Match the session list's plain full-row button, spacing and disclosure
    /// affordance. Independent rows keep shooter/facing history unambiguous.
    private func historyRow(player: StoredPlayer, destination: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: "#\(player.number) · \(player.name ?? "")")
                        .font(.headline)
                    Text(destination).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .background(Color.clear)
            .contentShape(.interaction, Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

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

    /// Archive instead of deleting: both shooting and goalkeeper facing
    /// associations and every match snapshot remain reachable.
    private func remove(_ stored: StoredPlayer) {
        do {
            // Archive even zero-shot identities: match participation and keeper
            // facing links are history too. Never delete an existing person.
            stored.archivedAt = .now
            try modelContext.save()
            editingPlayer = nil
        } catch {
            modelContext.rollback()
            actionError = RosterActionError(error)
        }
    }

}

/// Card routes retain stable person identity, never a reused shirt number.
private struct ShooterCardRoute: Hashable {
    let playerID: UUID
}

private struct GoalkeeperCardRoute: Hashable {
    let playerID: UUID
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

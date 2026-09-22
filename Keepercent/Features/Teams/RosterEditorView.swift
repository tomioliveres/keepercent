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

    var body: some View {
        Group {
            switch rosterResult {
            case .success(let roster):
                RosterGridView(
                    players: roster.players,
                    onSelectPlayer: { player in
                        editingPlayer = team.players.first { $0.number == player.number }
                    },
                    onTapAddUnknown: {
                        addUnknownErrorMessage = nil
                        isAddingUnknown = true
                    }
                )
            case .failure(let error):
                ContentUnavailableView {
                    Label("Roster Data Problem", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("This team's roster couldn't be loaded (\(error.localizedDescription)). Recorded shots are unaffected.")
                }
            }
        }
        .navigationTitle(team.name)
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
            actionError = RosterActionError(error)
        }
    }
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

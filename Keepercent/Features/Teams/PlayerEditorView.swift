// PlayerEditorView edits one player's name, goalkeeper flag, handedness
// and shirt number, and offers removal (docs/mvp.md §6 items 1, T3.1
// items 4-5). PRESENTATIONAL per CLAUDE.md: it receives a
// `KeepercentDomain.Player` draft plus a plain shot count and reports back
// through closures. It never sees `StoredPlayer` or `ModelContext` — the
// container (`RosterEditorView`) runs every edit through
// `Roster.update`/`Roster.remove` before touching SwiftData, so this view
// never re-implements the domain's uniqueness, range or shot-count rules.
//
// Delete affordance decision: the "Remove Player" button is always
// enabled, never pre-emptively greyed out. Disabling it here would need
// this view to decide on its own whether the player currently "has
// shots" — exactly the rule `Roster.remove` owns, and CLAUDE.md is
// explicit that a view must never re-implement a rule the domain already
// owns. So the button always tries, `Roster.remove` is what actually
// decides, and a refusal is explained by reading straight from
// `RosterError.playerHasRecordedShots`'s own payload (`rosterErrorMessage`
// in RosterErrorMessaging.swift) — never a locally-computed guess. The
// "Recorded shots" row below is purely informational (a straight read of
// `shotCount`, not a re-implementation of the removal rule), so the scout
// can see the number before even trying to remove the player, and isn't
// surprised by the alert when it appears.

import SwiftUI
import KeepercentDomain

struct PlayerEditorView: View {
    let shotCount: Int
    let onSave: (Player) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var numberText: String
    @State private var name: String
    @State private var isGoalkeeper: Bool
    @State private var handedness: Handedness?
    @State private var isConfirmingDelete = false

    init(player: Player, shotCount: Int, onSave: @escaping (Player) -> Void, onDelete: @escaping () -> Void) {
        self.shotCount = shotCount
        self.onSave = onSave
        self.onDelete = onDelete
        _numberText = State(initialValue: String(player.number))
        _name = State(initialValue: player.name ?? "")
        _isGoalkeeper = State(initialValue: player.isGoalkeeper)
        _handedness = State(initialValue: player.handedness)
    }

    /// Parsing "is this text an integer" is a type concern, not a business
    /// rule — the actual range (`Roster.numberRange`) is enforced by the
    /// domain when `onSave` runs, and reported back by the container.
    private var parsedNumber: Int? {
        Int(numberText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Shirt Number") {
                    TextField("Number", text: $numberText)
                        .keyboardType(.numberPad)
                }

                Section("Player") {
                    TextField("Name (optional)", text: $name)
                    Toggle("Goalkeeper", isOn: $isGoalkeeper)
                    Picker("Handedness", selection: $handedness) {
                        Text("Unknown").tag(Handedness?.none)
                        ForEach(Handedness.allCases, id: \.self) { hand in
                            Text(hand == .left ? "Left" : "Right").tag(Handedness?.some(hand))
                        }
                    }
                }

                Section {
                    LabeledContent("Recorded shots", value: "\(shotCount)")
                } footer: {
                    if shotCount > 0 {
                        Text("This player has recorded shots. Removal will be refused until they're gone.")
                    }
                }

                Section {
                    Button("Remove Player", role: .destructive) {
                        isConfirmingDelete = true
                    }
                }
            }
            .navigationTitle("Edit Player")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let number = parsedNumber else { return }
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(Player(
                            number: number,
                            name: trimmedName.isEmpty ? nil : trimmedName,
                            isGoalkeeper: isGoalkeeper,
                            handedness: handedness
                        ))
                    }
                    .disabled(parsedNumber == nil)
                }
            }
            .confirmationDialog(
                "Remove this player?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Remove Player", role: .destructive, action: onDelete)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This can't be undone. If shots are recorded against this player, removal will be refused and explained.")
            }
        }
    }
}

#Preview("PlayerEditorView") {
    PlayerEditorView(
        player: Player(number: 7, name: "Ana", isGoalkeeper: false, handedness: .right),
        shotCount: 0,
        onSave: { _ in },
        onDelete: {}
    )
}

#Preview("PlayerEditorView - Has Shots") {
    PlayerEditorView(
        player: Player(number: 1, name: "Marta", isGoalkeeper: true, handedness: .left),
        shotCount: 12,
        onSave: { _ in },
        onDelete: {}
    )
}

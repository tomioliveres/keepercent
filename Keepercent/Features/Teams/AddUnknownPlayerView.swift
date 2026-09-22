// AddUnknownPlayerView is the "+" tile's sheet (docs/mvp.md §6: "A '+'
// tile adds an unknown number during entry, without leaving the screen").
// PRESENTATIONAL per CLAUDE.md: it asks only for a shirt number and
// reports it back through a closure. It never calls into
// `KeepercentDomain.Roster` itself, and it never hardcodes the legal
// range — `allowedRange` and `errorMessage` both come from the container,
// which reads them straight from `Roster.numberRange` and from whatever
// `RosterError` it caught (see RosterErrorMessaging.swift), so this view
// can never drift from the domain's own bounds.

import SwiftUI

struct AddUnknownPlayerView: View {
    let allowedRange: ClosedRange<Int>
    let errorMessage: String?
    let onAdd: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var numberText = ""

    /// Parsing "is this text an integer" is a type concern, not a business
    /// rule — the actual legal range is enforced by `Roster.addUnknown`
    /// when `onAdd` runs, and reported back as `errorMessage`.
    private var parsedNumber: Int? {
        Int(numberText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Shirt number", text: $numberText)
                        .keyboardType(.numberPad)
                } footer: {
                    Text("Allowed range: \(allowedRange.lowerBound)–\(allowedRange.upperBound).")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Unknown Number")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard let number = parsedNumber else { return }
                        onAdd(number)
                    }
                    .disabled(parsedNumber == nil)
                }
            }
        }
    }
}

#Preview("AddUnknownPlayerView") {
    AddUnknownPlayerView(allowedRange: 1...99, errorMessage: nil, onAdd: { _ in })
}

#Preview("AddUnknownPlayerView - Error") {
    AddUnknownPlayerView(
        allowedRange: 1...99,
        errorMessage: "#7 is already used by another player on this roster.",
        onAdd: { _ in }
    )
}

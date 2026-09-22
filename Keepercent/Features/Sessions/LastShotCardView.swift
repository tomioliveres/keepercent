// LastShotCardView draws the one-level-undo card (docs/mvp.md §6 item 3,
// T3.3 decision ④): "the card echoes exactly what was stored, next to a
// large Undo and a haptic. After undoing, it shows 'Shot removed' without a
// button, so a double tap can never delete a second, correct shot."
//
// That last clause is enforced by this file's SHAPE, not by a disabled
// flag: `.removed` simply has no button in its view. There is no way to
// tap what was never drawn, so a second undo of the same shot is
// unreachable by construction rather than merely guarded against.
//
// PRESENTATIONAL per CLAUDE.md: it draws the plain `LastShotCardState` it
// is given and reports a tap through a closure — no SwiftData, no
// `StoredShot`. `SessionView` (the container) is the one place that turns
// a `Shot`/`ShotSummary` into the `.recorded(text:)` case, and the one
// place that decides when `.removed` expires back to `nil` — see its own
// header comment.

import SwiftUI

/// What the last-shot card shows: either the shot that was just recorded,
/// or the transient acknowledgement that it was undone. `nil` (owned by the
/// container) means "no card at all" — nothing has been recorded yet in
/// this session, or the last card already expired.
enum LastShotCardState: Equatable {
    /// `text` is `ShotSummary(shot:).text`, already formatted — this view
    /// stays free of any domain import, matching `SessionRowView`'s own
    /// "plain values only" contract.
    case recorded(text: String)
    case removed
}

struct LastShotCardView: View {
    let state: LastShotCardState
    let onUndo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch state {
            case .recorded(let text):
                Text(text)
                    .font(.subheadline.monospaced())
                    .fixedSize(horizontal: false, vertical: true)

                // "Large Undo button" per docs/mvp.md §6 item 3: a full-width
                // prominent button, not a small icon, since a mis-tap here
                // is exactly the safety net this card exists to provide.
                Button(action: onUndo) {
                    Text("Undo")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

            case .removed:
                Text("Shot removed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                // Deliberately no button here — see this file's header.
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .animation(.default, value: state)
    }
}

#Preview("LastShotCardView - Recorded") {
    LastShotCardView(state: .recorded(text: "#7 · left back · crossbar center · POST"), onUndo: {})
        .padding()
}

#Preview("LastShotCardView - Removed") {
    LastShotCardView(state: .removed, onUndo: {})
        .padding()
}

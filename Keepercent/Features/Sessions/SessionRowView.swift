// SessionRowView draws one row in a team's session list (T3.2 item 4).
// PRESENTATIONAL per CLAUDE.md: it draws only the plain values it is
// given — never a `StoredSession` — so a corrupt `kindCode` that fails to
// decode into a `SessionKind` (`kind == nil`, see StoredSession.swift)
// still renders as "Unknown kind" instead of crashing the row or the row
// silently vanishing from the list.

import SwiftUI
import KeepercentDomain

struct SessionRowView: View {
    let kind: SessionKind?
    let matchDate: Date
    let shotCount: Int

    private var kindText: String {
        kind.map(sessionKindLabel) ?? "Unknown kind"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(kindText)
                    .font(.headline)
                Text(matchDate, format: .dateTime.year().month().day())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(shotCount) shot\(shotCount == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 8)
    }
}

#Preview("SessionRowView") {
    VStack(spacing: 0) {
        SessionRowView(kind: .live, matchDate: .now, shotCount: 12)
        Divider()
        SessionRowView(kind: .video, matchDate: .now.addingTimeInterval(-86400 * 3), shotCount: 0)
        Divider()
        SessionRowView(kind: nil, matchDate: .now, shotCount: 5)
    }
    .padding(.horizontal)
}

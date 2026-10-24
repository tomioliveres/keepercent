import SwiftUI
import SwiftData
import KeepercentDomain

/// Shared container for global/team-local management. Entry and statistics still
/// use the same persisted match; editing never replaces it or its snapshots.
struct ManagedMatchRow: View {
    let session: StoredSession
    var showsRival = true
    let onOpen: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isEditing = false
    @State private var isDeleting = false
    @State private var kind: SessionKind = .live
    @State private var date: Date = .now
    @State private var errorMessage: String?

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
            : AnyLayout(HStackLayout())
        return layout {
            if session.rivalTeam != nil {
                Button(action: onOpen) { summary }
                    .buttonStyle(.plain)
            } else {
                summary
            }
            Menu { actions } label: {
                Image(systemName: "ellipsis.circle").frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("Match Actions")
        }
        .contextMenu { actions }
        .swipeActions(allowsFullSwipe: false) {
            // Don't give the swipe button a destructive role: the row must stay
            // visible until the scout explicitly confirms the alert.
            Button("Delete") { isDeleting = true }.tint(.red)
            Button("Edit", action: beginEditing)
        }
        .sheet(isPresented: $isEditing) {
            EditMatchSheet(kind: $kind, date: $date, errorMessage: errorMessage) {
                do {
                    try ScoutingDataActions.edit(session, kind: kind, date: date, in: modelContext)
                    isEditing = false
                } catch { errorMessage = sessionErrorMessage(error) }
            }
        }
        .alert("Delete this match?", isPresented: $isDeleting) {
            Button("Delete Match", role: .destructive) {
                do { try ScoutingDataActions.delete(session, in: modelContext) }
                catch { errorMessage = error.localizedDescription }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes this match, all its recorded shots and its participant snapshots. This cannot be undone.")
        }
        .alert("Couldn't Complete Action", isPresented: Binding(
            get: { errorMessage != nil && !isEditing }, set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showsRival {
                if let rival = session.rivalTeam { Text(rival.name).font(.headline) }
                else { Text("Deleted Rival").font(.headline) }
            }
            SessionRowView(kind: session.kind, matchDate: session.date, shotCount: session.shots.count)
            if session.rivalTeam == nil {
                Text("Shot entry is unavailable because this rival was deleted.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    @ViewBuilder private var actions: some View {
        Button("Edit Match", action: beginEditing)
        Button("Delete Match", role: .destructive) { isDeleting = true }
    }

    private func beginEditing() {
        kind = session.kind ?? .live
        date = session.date
        errorMessage = nil
        isEditing = true
    }
}

/// Value-only form: the container owns validation, persistence and errors.
private struct EditMatchSheet: View {
    @Binding var kind: SessionKind
    @Binding var date: Date
    let errorMessage: String?
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Picker("Kind", selection: $kind) {
                    ForEach(SessionKind.allCases, id: \.self) { Text(sessionKindLabel($0)).tag($0) }
                }
                .pickerStyle(.segmented)
                DatePicker("Match Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                if let errorMessage { Text(errorMessage).foregroundStyle(Palette.error) }
            }
            .navigationTitle("Edit Match")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: onSave) }
            }
        }
    }
}
